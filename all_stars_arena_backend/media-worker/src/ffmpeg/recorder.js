import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';

export class FfmpegRecorder {
  constructor(recordingId, rtspUrl, outputDir) {
    this.recordingId = recordingId;
    this.rtspUrl = rtspUrl;
    this.outputDir = outputDir;
    this.process = null;
    this.isRecording = false;
    this.outputFile = null;
  }

  start() {
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }

    this.outputFile = path.join(
      this.outputDir,
      `recording_${this.recordingId}_${Date.now()}.mp4`
    );

    const ffmpegBinary = process.env.FFMPEG_PATH || 'ffmpeg';

    // FFmpeg arguments for low-latency RTSP stream capture and mp4 streaming compatibility
    const ffmpegArgs = [
      '-rtsp_transport', 'tcp',
      '-stimeout', '10000000', // 10-second socket timeout
      '-i', this.rtspUrl,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-f', 'mp4',
      '-movflags', '+faststart',
      '-y',
      this.outputFile,
    ];

    this.process = spawn(ffmpegBinary, ffmpegArgs, {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    this.isRecording = true;

    this.process.stderr.on('data', (_chunk) => {
      // Progress stream data (omitted to keep logs clean)
    });

    this.process.on('close', (_code) => {
      this.isRecording = false;
    });

    this.process.on('error', (_err) => {
      this.isRecording = false;
    });

    return this.outputFile;
  }

  stop() {
    return new Promise((resolve) => {
      if (this.process && this.isRecording) {
        this.process.on('close', () => {
          this.isRecording = false;
          resolve(this.outputFile);
        });

        this.process.kill('SIGINT');

        setTimeout(() => {
          if (this.isRecording && this.process) {
            this.process.kill('SIGTERM');
            this.isRecording = false;
            resolve(this.outputFile);
          }
        }, 3000);
      } else {
        resolve(this.outputFile);
      }
    });
  }
}
