import { env } from "../config/env.config.js";
import { logger } from "../utils/logger.js";
import { CctvRecordingService } from "./cctvRecording.service.js";

export interface DiscoveredCamera {
  id: string;
  channel: number;
  name: string;
  courtName?: string;
  status: "available" | "unavailable" | "offline";
  healthStatus: "ONLINE" | "OFFLINE";
  ipAddress: string;
  port: number;
  protocol: string;
  supportedSubtypes: string[];
}

export class CctvDiscoveryService {
  private static cachedCameras: DiscoveredCamera[] | null = null;
  private static lastDiscoveryTimestamp = 0;
  private static ttlMs = 30000; // 30 seconds discovery cache

  /**
   * Discover and probe configured camera channels on the DVR host.
   */
  static async discoverCameras(
    forceRefresh = false,
  ): Promise<DiscoveredCamera[]> {
    const now = Date.now();
    if (
      !forceRefresh &&
      this.cachedCameras &&
      now - this.lastDiscoveryTimestamp < this.ttlMs
    ) {
      return this.cachedCameras;
    }

    const host = env.CAMERA_HOST || "192.168.1.2";
    const port = env.CAMERA_RTSP_PORT || 554;

    // Test overall DVR host reachability
    const hostTest = await CctvRecordingService.testCameraConnection({
      id: "dvr_host_discovery",
      ip_address: host,
      port,
      rtsp_url_encrypted: "",
    });

    const isHostOnline = hostTest.status === "ONLINE";

    // Configured camera channel descriptors
    const configuredChannels = [
      { channel: 1, name: "Court Camera 1 (Main Pitch)", courtName: "Court 1" },
      {
        channel: 2,
        name: "Court Camera 2 (Sideline View)",
        courtName: "Court 1",
      },
      { channel: 3, name: "Court Camera 3 (Side Pitch)", courtName: "Court 2" },
      {
        channel: 4,
        name: "Court Camera 4 (Goalpost View)",
        courtName: "Court 2",
      },
    ];

    const discoveredList: DiscoveredCamera[] = [];

    for (const c of configuredChannels) {
      // Probing individual channel
      let isChannelOnline = isHostOnline;
      if (isHostOnline) {
        const chTest = await CctvRecordingService.testCameraConnection({
          id: `dvr_discovery_ch_${c.channel}`,
          ip_address: host,
          port,
          rtsp_url_encrypted: "",
        });
        isChannelOnline = chTest.status === "ONLINE";
      }

      discoveredList.push({
        id: `channel-${c.channel}`,
        channel: c.channel,
        name: c.name,
        courtName: c.courtName,
        status: isChannelOnline ? "available" : "unavailable",
        healthStatus: isChannelOnline ? "ONLINE" : "OFFLINE",
        ipAddress: host,
        port,
        protocol: "rtsp",
        supportedSubtypes: ["main", "sub"],
      });
    }

    this.cachedCameras = discoveredList;
    this.lastDiscoveryTimestamp = now;

    logger.info(
      `🔍 [CCTV Discovery] Discovered ${discoveredList.length} channels (Host ${host}:${port} status: ${isHostOnline ? "ONLINE" : "OFFLINE"})`,
    );

    return discoveredList;
  }

  /**
   * Invalidate cache to force fresh discovery.
   */
  static clearCache(): void {
    this.cachedCameras = null;
    this.lastDiscoveryTimestamp = 0;
  }
}
