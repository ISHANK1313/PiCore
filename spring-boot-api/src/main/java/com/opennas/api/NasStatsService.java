package com.opennas.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * PiCore — NAS Stats Service
 * Reads live hardware metrics from /proc and /sys.
 * vcgencmd and Docker data are cached on a schedule.
 */
@Service
public class NasStatsService {

    @Value("${nas.proc.path:/host/proc}")
    private String procPath;

    @Value("${nas.sys.path:/host/sys}")
    private String sysPath;

    @Value("${nas.data.path:/mnt/data}")
    private String dataPath;

    // ── Cached values (refresh on schedule) ──────────────────────────────
    private volatile String cachedThrottleHex = "N/A";
    private volatile String cachedVoltage = "N/A";
    private volatile Double cachedGpuTemp = null;
    private volatile List<String> cachedContainerNames = new ArrayList<>();
    private volatile int cachedContainerCount = 0;

    @Scheduled(fixedDelay = 15000)
    public void refreshVcgencmd() {
        cachedThrottleHex = runCommand("vcgencmd", "get_throttled")
                .replace("throttled=", "").trim();
        String voltageRaw = runCommand("vcgencmd", "measure_volts", "core");
        cachedVoltage = voltageRaw.replace("volt=", "").trim();
        String gpuRaw = runCommand("vcgencmd", "measure_temp");
        try {
            cachedGpuTemp = Double.parseDouble(
                gpuRaw.replace("temp=", "").replace("'C", "").trim());
        } catch (Exception ignored) {}
    }

    @Scheduled(fixedDelay = 30000)
    public void refreshDockerContainers() {
        try {
            Process p = Runtime.getRuntime().exec(
                new String[]{"docker", "ps", "--format", "{{.Names}}"});
            List<String> names = new ArrayList<>();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(p.getInputStream()))) {
                String line;
                while ((line = br.readLine()) != null) {
                    if (!line.isBlank()) names.add(line.trim());
                }
            }
            cachedContainerNames = names;
            cachedContainerCount = names.size();
        } catch (Exception ignored) {}
    }

    public NasStats collectStats() throws Exception {
        NasStats s = new NasStats();

        // CPU temp
        s.setCpuTempCelsius(readCpuTemp());
        s.setGpuTempCelsius(cachedGpuTemp);

        // CPU usage (two-sample delta — 250ms sleep mandatory)
        long[] snap1 = readProcStat();
        Thread.sleep(250);
        long[] snap2 = readProcStat();
        s.setCpuUsagePercent(calculateCpuUsage(snap1, snap2));

        // CPU frequency
        s.setCpuFreqMHz(readCpuFreq("scaling_cur_freq"));
        s.setCpuMaxFreqMHz(readCpuFreq("scaling_max_freq"));
        s.setCpuMinFreqMHz(readCpuFreq("scaling_min_freq"));
        s.setCpuCores(Runtime.getRuntime().availableProcessors());

        // Load averages
        String[] load = readFile(procPath + "/loadavg").split("\\s+");
        s.setLoadAvg1m(Double.parseDouble(load[0]));
        s.setLoadAvg5m(Double.parseDouble(load[1]));
        s.setLoadAvg15m(Double.parseDouble(load[2]));

        // Context switches and interrupts from /proc/stat
        readStatExtras(s);

        // Power
        s.setThrottleHex(cachedThrottleHex);
        s.setCpuVoltage(cachedVoltage);
        s.setThrottleStatus(parseThrottleStatus(cachedThrottleHex));
        s.setVoltageStatus(parseVoltageStatus(cachedThrottleHex));

        // Memory
        readMemInfo(s);

        // Disk — OS
        readDiskUsage("/", s, false);

        // Disk — Data drive
        try {
            readDiskUsage(dataPath, s, true);
        } catch (Exception ignored) {}

        // Disk I/O
        readDiskIO(s);

        // Network
        readNetworkStats(s);

        // Uptime
        double uptime = Double.parseDouble(readFile(procPath + "/uptime").split("\\s+")[0]);
        s.setUptimeSeconds(uptime);
        s.setUptimeFormatted(formatUptime((long) uptime));

        // Processes/threads
        readProcessCount(s);

        // Containers
        s.setActiveContainers(cachedContainerCount);
        s.setContainerNames(cachedContainerNames);

        // System info
        s.setHostname(readFile(procPath + "/sys/kernel/hostname").trim());
        s.setKernelVersion(parseKernelVersion());
        s.setArchitecture(System.getProperty("os.arch"));
        s.setOsName(parseOsName());
        s.setNtpStatus(readNtpStatus());
        s.setSystemTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));

        return s;
    }

    // ── Private helpers ───────────────────────────────────────────────────

    private double readCpuTemp() {
        try {
            String raw = readFile(sysPath + "/class/thermal/thermal_zone0/temp");
            return Double.parseDouble(raw.trim()) / 1000.0;
        } catch (Exception e) { return 0.0; }
    }

    private long[] readProcStat() throws Exception {
        String line = Files.lines(Path.of(procPath + "/stat"))
            .filter(l -> l.startsWith("cpu ")).findFirst().orElse("");
        String[] parts = line.trim().split("\\s+");
        long[] vals = new long[parts.length - 1];
        for (int i = 0; i < vals.length; i++) vals[i] = Long.parseLong(parts[i+1]);
        return vals;
    }

    private double calculateCpuUsage(long[] s1, long[] s2) {
        // idle = index 3, iowait = index 4
        long idle1 = s1[3] + (s1.length > 4 ? s1[4] : 0);
        long idle2 = s2[3] + (s2.length > 4 ? s2[4] : 0);
        long total1 = Arrays.stream(s1).sum();
        long total2 = Arrays.stream(s2).sum();
        long totalDelta = total2 - total1;
        long idleDelta = idle2 - idle1;
        if (totalDelta == 0) return 0.0;
        return Math.round(((double)(totalDelta - idleDelta) / totalDelta) * 1000.0) / 10.0;
    }

    private void readStatExtras(NasStats s) {
        try {
            Files.lines(Path.of(procPath + "/stat")).forEach(line -> {
                if (line.startsWith("ctxt "))
                    s.setContextSwitches(Long.parseLong(line.split("\\s+")[1]));
                if (line.startsWith("intr "))
                    s.setInterrupts(Long.parseLong(line.split("\\s+")[1]));
            });
        } catch (Exception ignored) {}
    }

    private Double readCpuFreq(String filename) {
        try {
            String raw = readFile(sysPath + "/devices/system/cpu/cpu0/cpufreq/" + filename);
            return Double.parseDouble(raw.trim()) / 1000.0;
        } catch (Exception e) { return null; }
    }

    private void readMemInfo(NasStats s) {
        try {
            Map<String, Long> mem = new HashMap<>();
            Files.lines(Path.of(procPath + "/meminfo")).forEach(line -> {
                String[] parts = line.split(":\\s+");
                if (parts.length == 2)
                    mem.put(parts[0].trim(), Long.parseLong(parts[1].replace("kB","").trim()));
            });
            long total = mem.getOrDefault("MemTotal", 0L) / 1024;
            long free = mem.getOrDefault("MemFree", 0L) / 1024;
            long available = mem.getOrDefault("MemAvailable", 0L) / 1024;
            long used = total - available;
            s.setMemoryTotalMB(total);
            s.setMemoryUsedMB(used);
            s.setMemoryFreeMB(free);
            s.setMemoryAvailableMB(available);
            s.setMemoryCachedMB(mem.getOrDefault("Cached", 0L) / 1024);
            s.setMemoryBuffersMB(mem.getOrDefault("Buffers", 0L) / 1024);
            s.setMemorySharedMB(mem.getOrDefault("Shmem", 0L) / 1024);
            s.setMemoryDirtyMB(mem.getOrDefault("Dirty", 0L) / 1024);
            s.setMemoryUsedPercent(total > 0 ? Math.round((double)used/total*1000)/10.0 : 0);
            long swapTotal = mem.getOrDefault("SwapTotal", 0L) / 1024;
            long swapFree = mem.getOrDefault("SwapFree", 0L) / 1024;
            long swapUsed = swapTotal - swapFree;
            s.setSwapTotalMB(swapTotal);
            s.setSwapUsedMB(swapUsed);
            s.setSwapFreeMB(swapFree);
            s.setSwapUsedPercent(swapTotal > 0 ? Math.round((double)swapUsed/swapTotal*1000)/10.0 : 0);
        } catch (Exception ignored) {}
    }

    private void readDiskUsage(String path, NasStats s, boolean isDataDrive) {
        try {
            File f = new File(path);
            long total = f.getTotalSpace();
            long free = f.getFreeSpace();
            long used = total - free;
            double totalGB = Math.round(total / 1024.0 / 1024 / 1024 * 10) / 10.0;
            double usedGB = Math.round(used / 1024.0 / 1024 / 1024 * 10) / 10.0;
            double freeGB = Math.round(free / 1024.0 / 1024 / 1024 * 10) / 10.0;
            double pct = total > 0 ? Math.round((double)used/total*1000)/10.0 : 0;
            if (isDataDrive) {
                s.setDataDiskTotalGB(totalGB);
                s.setDataDiskUsedGB(usedGB);
                s.setDataDiskFreeGB(freeGB);
                s.setDataDiskUsedPercent(pct);
            } else {
                s.setDiskTotalGB(totalGB);
                s.setDiskUsedGB(usedGB);
                s.setDiskFreeGB(freeGB);
                s.setDiskUsedPercent(pct);
            }
        } catch (Exception ignored) {}
    }

    private void readDiskIO(NasStats s) {
        try {
            Optional<String> line = Files.lines(Path.of(procPath + "/diskstats"))
                .filter(l -> l.contains(" sdc ") || l.contains(" sda "))
                .findFirst();
            if (line.isPresent()) {
                String[] p = line.get().trim().split("\\s+");
                long reads = Long.parseLong(p[5]) * 512;
                long writes = Long.parseLong(p[9]) * 512;
                s.setDiskReadBytes(reads);
                s.setDiskWriteBytes(writes);
                s.setDiskReadHuman(formatBytes(reads));
                s.setDiskWriteHuman(formatBytes(writes));
                s.setDiskReadOps(Long.parseLong(p[3]));
                s.setDiskWriteOps(Long.parseLong(p[7]));
            }
        } catch (Exception ignored) {}
    }

    private void readNetworkStats(NasStats s) {
        try {
            Optional<String> line = Files.lines(Path.of(procPath + "/net/dev"))
                .filter(l -> l.contains("wlan0") || l.contains("eth0"))
                .findFirst();
            if (line.isPresent()) {
                String[] p = line.get().trim().split("\\s+");
                s.setNetworkRxBytes(Long.parseLong(p[1]));
                s.setNetworkTxBytes(Long.parseLong(p[9]));
                s.setNetworkRxPackets(Long.parseLong(p[2]));
                s.setNetworkTxPackets(Long.parseLong(p[10]));
                s.setNetworkRxErrors(Long.parseLong(p[3]));
                s.setNetworkTxErrors(Long.parseLong(p[11]));
                s.setNetworkRxDropped(Long.parseLong(p[4]));
                s.setNetworkTxDropped(Long.parseLong(p[12]));
                s.setNetworkRxKbps(Math.round(Long.parseLong(p[1]) / 1024.0 * 10) / 10.0);
                s.setNetworkTxKbps(Math.round(Long.parseLong(p[9]) / 1024.0 * 10) / 10.0);
            }
        } catch (Exception ignored) {}
    }

    private void readProcessCount(NasStats s) {
        try {
            long procs = Files.list(Path.of(procPath))
                .filter(p -> p.getFileName().toString().matches("\\d+"))
                .count();
            s.setProcessCount((int) procs);
        } catch (Exception ignored) {}
    }

    private String parseThrottleStatus(String hex) {
        if (hex == null || hex.equals("N/A") || hex.equals("0x0")) return "NONE";
        long val;
        try { val = Long.decode(hex); } catch (Exception e) { return "UNKNOWN"; }
        if ((val & 0x4) != 0) return "THROTTLED";
        if ((val & 0x1) != 0) return "UNDER_VOLTAGE";
        if ((val & 0x40000) != 0) return "THROTTLED_PREVIOUSLY";
        return "OK";
    }

    private String parseVoltageStatus(String hex) {
        if (hex == null || hex.equals("N/A")) return "UNKNOWN";
        try {
            long val = Long.decode(hex);
            return ((val & 0x10001) != 0) ? "UNDER_VOLTAGE_DETECTED" : "OK";
        } catch (Exception e) { return "UNKNOWN"; }
    }

    private String parseKernelVersion() {
        try {
            return readFile(procPath + "/version").split("\\s+")[2];
        } catch (Exception e) { return "unknown"; }
    }

    private String parseOsName() {
        try {
            return Files.lines(Path.of("/etc/os-release"))
                .filter(l -> l.startsWith("PRETTY_NAME"))
                .findFirst()
                .map(l -> l.replace("PRETTY_NAME=","").replace("\"",""))
                .orElse("Linux");
        } catch (Exception e) { return "Linux"; }
    }

    private String readNtpStatus() {
        try {
            Process p = Runtime.getRuntime().exec(new String[]{"timedatectl","show","--property=NTPSynchronized"});
            String out = new String(p.getInputStream().readAllBytes()).trim();
            return out.contains("yes") ? "SYNCED" : "NOT_SYNCED";
        } catch (Exception e) { return "N/A"; }
    }

    private String formatUptime(long seconds) {
        long days = seconds / 86400;
        long hours = (seconds % 86400) / 3600;
        long mins = (seconds % 3600) / 60;
        if (days > 0) return days + "d " + hours + "h";
        if (hours > 0) return hours + "h " + mins + "m";
        return mins + "m";
    }

    private String formatBytes(long bytes) {
        if (bytes >= 1_073_741_824) return Math.round(bytes / 1_073_741_824.0 * 10) / 10.0 + " GB";
        if (bytes >= 1_048_576) return Math.round(bytes / 1_048_576.0 * 10) / 10.0 + " MB";
        return Math.round(bytes / 1024.0 * 10) / 10.0 + " KB";
    }

    private String readFile(String path) throws IOException {
        return Files.readString(Path.of(path)).trim();
    }

    private String runCommand(String... cmd) {
        try {
            Process p = Runtime.getRuntime().exec(cmd);
            return new String(p.getInputStream().readAllBytes()).trim();
        } catch (Exception e) { return "N/A"; }
    }
}
