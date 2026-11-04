import { spawn, ChildProcess } from "child_process";
import path from "path";
import fs from "fs";
import { logger } from "../utils/logger.js";

export class TunnelService {
  private static process: ChildProcess | null = null;
  private static activeUrl: string | null = null;

  public static async start(port = 8599): Promise<string | null> {
    const cloudflaredPath = path.resolve(process.cwd(), "cloudflared.exe");
    if (!fs.existsSync(cloudflaredPath)) {
      logger.info(
        "cloudflared.exe not found in backend directory. Tunnel auto-start skipped.",
      );
      return null;
    }

    const infoPath = path.resolve(process.cwd(), "active_tunnel.json");
    if (fs.existsSync(infoPath)) {
      try {
        const cached = JSON.parse(fs.readFileSync(infoPath, "utf8"));
        if (cached && cached.url) {
          TunnelService.activeUrl = cached.url;
        }
      } catch (_) {}
    }

    if (TunnelService.activeUrl) {
      logger.info(
        `🌐 Existing Cloudflare Tunnel active: ${TunnelService.activeUrl}`,
      );
      return TunnelService.activeUrl;
    }

    return new Promise((resolve) => {
      logger.info(
        "🚀 Starting Cloudflare Tunnel for universal multi-network CCTV streaming...",
      );

      try {
        const child = spawn(
          cloudflaredPath,
          ["tunnel", "--url", `http://127.0.0.1:${port}`],
          {
            windowsHide: true,
            stdio: ["ignore", "pipe", "pipe"],
          },
        );

        TunnelService.process = child;

        const checkOutput = (data: Buffer) => {
          const text = data.toString();
          const match = text.match(/https:\/\/[a-z0-9-]+\.trycloudflare\.com/i);
          if (match && !TunnelService.activeUrl) {
            TunnelService.activeUrl = match[0];
            logger.info(
              "════════════════════════════════════════════════════════════════",
            );
            logger.info(`🌐 UNIVERSAL CLOUDFLARE TUNNEL ONLINE!`);
            logger.info(`   Public URL: ${TunnelService.activeUrl}`);
            logger.info(
              `   CCTV Live Stream: ${TunnelService.activeUrl}/cctv-stream/cam1_sub/index.m3u8`,
            );
            logger.info(
              `   (Works across MGMT BOTIVATE, 5G Mobile Data, & All WiFis)`,
            );
            logger.info(
              "════════════════════════════════════════════════════════════════",
            );

            try {
              fs.writeFileSync(
                infoPath,
                JSON.stringify(
                  {
                    url: TunnelService.activeUrl,
                    apiUrl: `${TunnelService.activeUrl}/api/v1`,
                    streamUrl: `${TunnelService.activeUrl}/cctv-stream`,
                    port,
                    updatedAt: new Date().toISOString(),
                  },
                  null,
                  2,
                ),
              );
            } catch (_) {}

            resolve(TunnelService.activeUrl);
          }
        };

        child.stdout?.on("data", checkOutput);
        child.stderr?.on("data", checkOutput);

        child.on("error", (err) => {
          logger.warn({ err }, "Could not launch cloudflared tunnel process");
          resolve(TunnelService.activeUrl);
        });

        child.on("exit", (code) => {
          if (code !== 0 && code !== null) {
            logger.warn(`Cloudflare Tunnel stopped (code ${code})`);
          }
          TunnelService.process = null;
        });

        setTimeout(() => {
          resolve(TunnelService.activeUrl);
        }, 8000);
      } catch (err) {
        logger.error({ err }, "Failed to start tunnel service");
        resolve(null);
      }
    });
  }

  public static getUrl(): string | null {
    if (!TunnelService.activeUrl) {
      const infoPath = path.resolve(process.cwd(), "active_tunnel.json");
      if (fs.existsSync(infoPath)) {
        try {
          const cached = JSON.parse(fs.readFileSync(infoPath, "utf8"));
          if (cached && cached.url) {
            TunnelService.activeUrl = cached.url;
          }
        } catch (_) {}
      }
    }
    return TunnelService.activeUrl;
  }

  public static setUrl(url: string): void {
    TunnelService.activeUrl = url;
    const infoPath = path.resolve(process.cwd(), "active_tunnel.json");
    try {
      fs.writeFileSync(
        infoPath,
        JSON.stringify(
          {
            url,
            apiUrl: `${url}/api/v1`,
            streamUrl: `${url}/cctv-stream`,
            updatedAt: new Date().toISOString(),
          },
          null,
          2,
        ),
      );
    } catch (_) {}
  }

  public static stop(): void {
    if (TunnelService.process) {
      try {
        TunnelService.process.kill();
      } catch (_) {}
      TunnelService.process = null;
    }
  }
}
