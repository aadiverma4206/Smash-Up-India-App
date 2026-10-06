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
  }

  start() {
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }

    const outputFile = path.join(this.outputDir, 'output.mp4');

    // FFmpeg arguments for low-latency RTSP stream capture
    const ffmpegArgs = [
      '-rtsp_transport', 'tcp',
      '-i', this.rtspUrl,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-f', 'mp4',
      '-movflags', 'frag_keyframe+empty_moov',
      '-y',
      outputFile,
    ];

    this.process = spawn('ffmpeg', ffmpegArgs);
    this.isRecording = true;

    this.process.stderr.on('data', (data) => {
      // Stream progress logging
    });

    this.process.on('close', (code) => {
      this.isRecording = false;
    });

    this.process.on('error', (err) => {
      this.isRecording = false;
    });

    return outputFile;
  }

  stop() {
    if (this.process && this.isRecording) {
      this.process.kill('SIGINT');
      this.isRecording = false;
    }
  }
}
