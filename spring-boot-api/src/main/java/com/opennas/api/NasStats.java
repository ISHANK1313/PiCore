package com.opennas.api;

import java.util.List;

/**
 * PiCore — NAS Stats Data Model
 * All 40+ hardware telemetry fields returned by /api/stats
 */
public class NasStats {

    // ── CPU ──────────────────────────────────────────────────────────────
    private double cpuTempCelsius;
    private Double gpuTempCelsius;
    private double cpuUsagePercent;
    private Double cpuIoWaitPercent;
    private Double cpuFreqMHz;
    private Double cpuMaxFreqMHz;
    private Double cpuMinFreqMHz;
    private int cpuCores;

    // ── Load Averages ─────────────────────────────────────────────────────
    private double loadAvg1m;
    private double loadAvg5m;
    private double loadAvg15m;
    private Long contextSwitches;
    private Long interrupts;

    // ── Power / Voltage ───────────────────────────────────────────────────
    private String cpuVoltage;
    private String throttleStatus;
    private String voltageStatus;
    private String throttleHex;

    // ── Memory ───────────────────────────────────────────────────────────
    private long memoryTotalMB;
    private long memoryUsedMB;
    private long memoryFreeMB;
    private Long memoryAvailableMB;
    private Long memoryCachedMB;
    private Long memoryBuffersMB;
    private Long memorySharedMB;
    private Long memoryDirtyMB;
    private double memoryUsedPercent;

    // ── Swap ─────────────────────────────────────────────────────────────
    private long swapTotalMB;
    private long swapUsedMB;
    private long swapFreeMB;
    private double swapUsedPercent;

    // ── Storage (OS Drive) ───────────────────────────────────────────────
    private double diskTotalGB;
    private double diskUsedGB;
    private double diskFreeGB;
    private double diskUsedPercent;

    // ── Storage (Data Drive /mnt/data) ───────────────────────────────────
    private Double dataDiskTotalGB;
    private Double dataDiskUsedGB;
    private Double dataDiskFreeGB;
    private Double dataDiskUsedPercent;

    // ── Disk I/O ─────────────────────────────────────────────────────────
    private Long diskReadBytes;
    private Long diskWriteBytes;
    private String diskReadHuman;
    private String diskWriteHuman;
    private Long diskReadOps;
    private Long diskWriteOps;

    // ── Network ──────────────────────────────────────────────────────────
    private long networkRxBytes;
    private long networkTxBytes;
    private double networkRxKbps;
    private double networkTxKbps;
    private Long networkRxPackets;
    private Long networkTxPackets;
    private Long networkRxErrors;
    private Long networkTxErrors;
    private Long networkRxDropped;
    private Long networkTxDropped;

    // ── System ───────────────────────────────────────────────────────────
    private double uptimeSeconds;
    private String uptimeFormatted;
    private int activeContainers;
    private List<String> containerNames;
    private String hostname;
    private String osName;
    private String kernelVersion;
    private String architecture;
    private Integer processCount;
    private Integer threadCount;
    private String ntpStatus;
    private String systemTime;

    // ── Getters and Setters ───────────────────────────────────────────────

    public double getCpuTempCelsius() { return cpuTempCelsius; }
    public void setCpuTempCelsius(double v) { this.cpuTempCelsius = v; }

    public Double getGpuTempCelsius() { return gpuTempCelsius; }
    public void setGpuTempCelsius(Double v) { this.gpuTempCelsius = v; }

    public double getCpuUsagePercent() { return cpuUsagePercent; }
    public void setCpuUsagePercent(double v) { this.cpuUsagePercent = v; }

    public Double getCpuIoWaitPercent() { return cpuIoWaitPercent; }
    public void setCpuIoWaitPercent(Double v) { this.cpuIoWaitPercent = v; }

    public Double getCpuFreqMHz() { return cpuFreqMHz; }
    public void setCpuFreqMHz(Double v) { this.cpuFreqMHz = v; }

    public Double getCpuMaxFreqMHz() { return cpuMaxFreqMHz; }
    public void setCpuMaxFreqMHz(Double v) { this.cpuMaxFreqMHz = v; }

    public Double getCpuMinFreqMHz() { return cpuMinFreqMHz; }
    public void setCpuMinFreqMHz(Double v) { this.cpuMinFreqMHz = v; }

    public int getCpuCores() { return cpuCores; }
    public void setCpuCores(int v) { this.cpuCores = v; }

    public double getLoadAvg1m() { return loadAvg1m; }
    public void setLoadAvg1m(double v) { this.loadAvg1m = v; }

    public double getLoadAvg5m() { return loadAvg5m; }
    public void setLoadAvg5m(double v) { this.loadAvg5m = v; }

    public double getLoadAvg15m() { return loadAvg15m; }
    public void setLoadAvg15m(double v) { this.loadAvg15m = v; }

    public Long getContextSwitches() { return contextSwitches; }
    public void setContextSwitches(Long v) { this.contextSwitches = v; }

    public Long getInterrupts() { return interrupts; }
    public void setInterrupts(Long v) { this.interrupts = v; }

    public String getCpuVoltage() { return cpuVoltage; }
    public void setCpuVoltage(String v) { this.cpuVoltage = v; }

    public String getThrottleStatus() { return throttleStatus; }
    public void setThrottleStatus(String v) { this.throttleStatus = v; }

    public String getVoltageStatus() { return voltageStatus; }
    public void setVoltageStatus(String v) { this.voltageStatus = v; }

    public String getThrottleHex() { return throttleHex; }
    public void setThrottleHex(String v) { this.throttleHex = v; }

    public long getMemoryTotalMB() { return memoryTotalMB; }
    public void setMemoryTotalMB(long v) { this.memoryTotalMB = v; }

    public long getMemoryUsedMB() { return memoryUsedMB; }
    public void setMemoryUsedMB(long v) { this.memoryUsedMB = v; }

    public long getMemoryFreeMB() { return memoryFreeMB; }
    public void setMemoryFreeMB(long v) { this.memoryFreeMB = v; }

    public Long getMemoryAvailableMB() { return memoryAvailableMB; }
    public void setMemoryAvailableMB(Long v) { this.memoryAvailableMB = v; }

    public Long getMemoryCachedMB() { return memoryCachedMB; }
    public void setMemoryCachedMB(Long v) { this.memoryCachedMB = v; }

    public Long getMemoryBuffersMB() { return memoryBuffersMB; }
    public void setMemoryBuffersMB(Long v) { this.memoryBuffersMB = v; }

    public Long getMemorySharedMB() { return memorySharedMB; }
    public void setMemorySharedMB(Long v) { this.memorySharedMB = v; }

    public Long getMemoryDirtyMB() { return memoryDirtyMB; }
    public void setMemoryDirtyMB(Long v) { this.memoryDirtyMB = v; }

    public double getMemoryUsedPercent() { return memoryUsedPercent; }
    public void setMemoryUsedPercent(double v) { this.memoryUsedPercent = v; }

    public long getSwapTotalMB() { return swapTotalMB; }
    public void setSwapTotalMB(long v) { this.swapTotalMB = v; }

    public long getSwapUsedMB() { return swapUsedMB; }
    public void setSwapUsedMB(long v) { this.swapUsedMB = v; }

    public long getSwapFreeMB() { return swapFreeMB; }
    public void setSwapFreeMB(long v) { this.swapFreeMB = v; }

    public double getSwapUsedPercent() { return swapUsedPercent; }
    public void setSwapUsedPercent(double v) { this.swapUsedPercent = v; }

    public double getDiskTotalGB() { return diskTotalGB; }
    public void setDiskTotalGB(double v) { this.diskTotalGB = v; }

    public double getDiskUsedGB() { return diskUsedGB; }
    public void setDiskUsedGB(double v) { this.diskUsedGB = v; }

    public double getDiskFreeGB() { return diskFreeGB; }
    public void setDiskFreeGB(double v) { this.diskFreeGB = v; }

    public double getDiskUsedPercent() { return diskUsedPercent; }
    public void setDiskUsedPercent(double v) { this.diskUsedPercent = v; }

    public Double getDataDiskTotalGB() { return dataDiskTotalGB; }
    public void setDataDiskTotalGB(Double v) { this.dataDiskTotalGB = v; }

    public Double getDataDiskUsedGB() { return dataDiskUsedGB; }
    public void setDataDiskUsedGB(Double v) { this.dataDiskUsedGB = v; }

    public Double getDataDiskFreeGB() { return dataDiskFreeGB; }
    public void setDataDiskFreeGB(Double v) { this.dataDiskFreeGB = v; }

    public Double getDataDiskUsedPercent() { return dataDiskUsedPercent; }
    public void setDataDiskUsedPercent(Double v) { this.dataDiskUsedPercent = v; }

    public Long getDiskReadBytes() { return diskReadBytes; }
    public void setDiskReadBytes(Long v) { this.diskReadBytes = v; }

    public Long getDiskWriteBytes() { return diskWriteBytes; }
    public void setDiskWriteBytes(Long v) { this.diskWriteBytes = v; }

    public String getDiskReadHuman() { return diskReadHuman; }
    public void setDiskReadHuman(String v) { this.diskReadHuman = v; }

    public String getDiskWriteHuman() { return diskWriteHuman; }
    public void setDiskWriteHuman(String v) { this.diskWriteHuman = v; }

    public Long getDiskReadOps() { return diskReadOps; }
    public void setDiskReadOps(Long v) { this.diskReadOps = v; }

    public Long getDiskWriteOps() { return diskWriteOps; }
    public void setDiskWriteOps(Long v) { this.diskWriteOps = v; }

    public long getNetworkRxBytes() { return networkRxBytes; }
    public void setNetworkRxBytes(long v) { this.networkRxBytes = v; }

    public long getNetworkTxBytes() { return networkTxBytes; }
    public void setNetworkTxBytes(long v) { this.networkTxBytes = v; }

    public double getNetworkRxKbps() { return networkRxKbps; }
    public void setNetworkRxKbps(double v) { this.networkRxKbps = v; }

    public double getNetworkTxKbps() { return networkTxKbps; }
    public void setNetworkTxKbps(double v) { this.networkTxKbps = v; }

    public Long getNetworkRxPackets() { return networkRxPackets; }
    public void setNetworkRxPackets(Long v) { this.networkRxPackets = v; }

    public Long getNetworkTxPackets() { return networkTxPackets; }
    public void setNetworkTxPackets(Long v) { this.networkTxPackets = v; }

    public Long getNetworkRxErrors() { return networkRxErrors; }
    public void setNetworkRxErrors(Long v) { this.networkRxErrors = v; }

    public Long getNetworkTxErrors() { return networkTxErrors; }
    public void setNetworkTxErrors(Long v) { this.networkTxErrors = v; }

    public Long getNetworkRxDropped() { return networkRxDropped; }
    public void setNetworkRxDropped(Long v) { this.networkRxDropped = v; }

    public Long getNetworkTxDropped() { return networkTxDropped; }
    public void setNetworkTxDropped(Long v) { this.networkTxDropped = v; }

    public double getUptimeSeconds() { return uptimeSeconds; }
    public void setUptimeSeconds(double v) { this.uptimeSeconds = v; }

    public String getUptimeFormatted() { return uptimeFormatted; }
    public void setUptimeFormatted(String v) { this.uptimeFormatted = v; }

    public int getActiveContainers() { return activeContainers; }
    public void setActiveContainers(int v) { this.activeContainers = v; }

    public List<String> getContainerNames() { return containerNames; }
    public void setContainerNames(List<String> v) { this.containerNames = v; }

    public String getHostname() { return hostname; }
    public void setHostname(String v) { this.hostname = v; }

    public String getOsName() { return osName; }
    public void setOsName(String v) { this.osName = v; }

    public String getKernelVersion() { return kernelVersion; }
    public void setKernelVersion(String v) { this.kernelVersion = v; }

    public String getArchitecture() { return architecture; }
    public void setArchitecture(String v) { this.architecture = v; }

    public Integer getProcessCount() { return processCount; }
    public void setProcessCount(Integer v) { this.processCount = v; }

    public Integer getThreadCount() { return threadCount; }
    public void setThreadCount(Integer v) { this.threadCount = v; }

    public String getNtpStatus() { return ntpStatus; }
    public void setNtpStatus(String v) { this.ntpStatus = v; }

    public String getSystemTime() { return systemTime; }
    public void setSystemTime(String v) { this.systemTime = v; }
}
