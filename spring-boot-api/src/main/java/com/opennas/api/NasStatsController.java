package com.opennas.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * PiCore — NAS Stats REST Controller
 * Exposes hardware telemetry endpoints
 */
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class NasStatsController {

    private final NasStatsService statsService;

    public NasStatsController(NasStatsService statsService) {
        this.statsService = statsService;
    }

    /**
     * GET /api/stats
     * Returns all 40+ live hardware metrics.
     * Note: Takes ~1.66s due to mandatory 250ms CPU sampling sleep.
     */
    @GetMapping("/stats")
    public ResponseEntity<NasStats> getStats() {
        try {
            NasStats stats = statsService.collectStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * GET /api/health
     * Liveness check for Uptime Kuma and reverse proxy health checks.
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "OpenNAS Dashboard"
        ));
    }
}
