import { spawn, ChildProcess } from "child_process";
import net from "net";
import path from "path";
import fs from "fs";
import { logger } from "../utils/logger.js";

/**
 * Service to manage local MediaMTX HLS / WebRTC streaming server
 */
export class MediaMtxService {
  private static process?: ChildProcess;

  /**
   * Check if MediaMTX HLS port 8888 is already listening
   */
  static isPortListening(
    port = 8888,
    host = "127.0.0.1",
    timeoutMs = 800,
  ): Promise<boolean> {
    return new Promise((resolve) => {
      const socket = new net.Socket();
      socket.setTimeout(timeoutMs);
      socket.once("connect", () => {
        socket.destroy();
        resolve(true);
      });
      socket.once("timeout", () => {
        socket.destroy();
        resolve(false);
      });
      socket.once("error", () => {
        socket.destroy();
        resolve(false);
      });
      socket.connect(port, host);
    });
  }

  /**
   * Ensure MediaMTX server is running. Spawns mediamtx.exe if not already active.
   */
  static async ensureRunning(): Promise<boolean> {
    const isListening = await this.isPortListening(8888);
    if (isListening) {
      logger.info(
        "📹 MediaMTX CCTV Server is already active on port 8888 (HLS) & 8889 (WebRTC)",
      );
      return true;
    }

    const cwd = process.cwd();
    const exePath = path.join(cwd, "mediamtx.exe");
    const ymlPath = path.join(cwd, "mediamtx.yml");

    if (!fs.existsSync(exePath) || !fs.existsSync(ymlPath)) {
      logger.warn(
        "📹 MediaMTX binary or config not found in backend directory. Skipping auto-start.",
      );
      return false;
    }

    try {
      logger.info("📹 Launching local MediaMTX CCTV Server (port 8888)...");
      this.process = spawn(exePath, [ymlPath], {
        cwd,
        stdio: ["ignore", "ignore", "ignore"],
        detached: true,
      });

      this.process.unref();

      // Wait briefly for port to bind
      for (let i = 0; i < 15; i++) {
        await new Promise((r) => setTimeout(r, 200));
        if (await this.isPortListening(8888)) {
          logger.info(
            "✅ MediaMTX CCTV Server successfully started on port 8888 (HLS)",
          );
          return true;
        }
      }

      logger.warn(
        "📹 MediaMTX process spawned but port 8888 not yet responding.",
      );
      return false;
    } catch (err: any) {
      logger.error(
        { err: err.message },
        "📹 Failed to launch MediaMTX process",
      );
      return false;
    }
  }
}
