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
  private static ttlMs = 30000;

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

    const hostTest = await CctvRecordingService.testCameraConnection({
      id: "dvr_host_discovery",
      ip_address: host,
      port,
      rtsp_url_encrypted: "",
    });

    const isHostOnline = hostTest.status === "ONLINE";

    const configuredChannels = [
      {
        channel: 1,
        name: "Camera 1 (Court 1 - Main Pitch)",
        courtName: "Court 1",
      },
      {
        channel: 2,
        name: "Camera 2 (Court 1 - Sideline)",
        courtName: "Court 1",
      },
      {
        channel: 3,
        name: "Camera 3 (Court 2 - Main Pitch)",
        courtName: "Court 2",
      },
      {
        channel: 4,
        name: "Camera 4 (Court 2 - Goalpost)",
        courtName: "Court 2",
      },
    ];

    const discoveredList: DiscoveredCamera[] = [];

    for (const c of configuredChannels) {
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

  static clearCache(): void {
    this.cachedCameras = null;
    this.lastDiscoveryTimestamp = 0;
  }
}
