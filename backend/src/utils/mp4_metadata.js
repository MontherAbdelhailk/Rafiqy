'use strict';

const fs = require('fs');

/**
 * Parses local MP4 file box headers to extract duration, resolution, and aspect ratio.
 * Runs in pure JS, providing extremely fast and reliable metadata parsing.
 * @param {string} filePath - Absolute path to the local video file.
 * @returns {Promise<{duration: string, resolution: string, aspect_ratio: string}>}
 */
async function parseMp4Metadata(filePath) {
  return new Promise((resolve) => {
    fs.open(filePath, 'r', (err, fd) => {
      if (err) {
        console.error('Error opening file for metadata extraction:', err);
        return resolve({ duration: '00:10', resolution: '1920x1080', aspect_ratio: '16:9' });
      }

      try {
        const stats = fs.fstatSync(fd);
        const fileSize = stats.size;
        
        let duration = null;
        let width = null;
        let height = null;

        const headerBuf = Buffer.alloc(8);

        function readNextBox(currentOffset) {
          if (currentOffset >= fileSize) {
            try { fs.closeSync(fd); } catch (e) {}
            return resolve(buildResult(duration, width, height));
          }

          let bytesRead = 0;
          try {
            bytesRead = fs.readSync(fd, headerBuf, 0, 8, currentOffset);
          } catch (e) {
            try { fs.closeSync(fd); } catch (e) {}
            return resolve(buildResult(duration, width, height));
          }

          if (bytesRead < 8) {
            try { fs.closeSync(fd); } catch (e) {}
            return resolve(buildResult(duration, width, height));
          }

          let size = headerBuf.readUInt32BE(0);
          const type = headerBuf.toString('ascii', 4, 8);

          if (size === 1) {
            const sizeBuf = Buffer.alloc(8);
            try {
              fs.readSync(fd, sizeBuf, 0, 8, currentOffset + 8);
              size = sizeBuf.readUInt32BE(4); // Use lower 32-bits
            } catch (e) {
              try { fs.closeSync(fd); } catch (e) {}
              return resolve(buildResult(duration, width, height));
            }
          }

          if (size <= 0) {
            size = fileSize - currentOffset;
          }

          if (type === 'moov') {
            scanContainer(currentOffset + 8, size - 8);
            try { fs.closeSync(fd); } catch (e) {}
            return resolve(buildResult(duration, width, height));
          } else {
            readNextBox(currentOffset + size);
          }
        }

        function scanContainer(containerOffset, containerSize) {
          let innerOffset = containerOffset;
          const endOffset = containerOffset + containerSize;

          const innerHeader = Buffer.alloc(8);
          while (innerOffset < endOffset) {
            let bytesRead = 0;
            try {
              bytesRead = fs.readSync(fd, innerHeader, 0, 8, innerOffset);
            } catch (e) {
              break;
            }
            if (bytesRead < 8) break;

            let size = innerHeader.readUInt32BE(0);
            const type = innerHeader.toString('ascii', 4, 8);

            if (size === 1) {
              const sizeBuf = Buffer.alloc(8);
              try {
                fs.readSync(fd, sizeBuf, 0, 8, innerOffset + 8);
                size = sizeBuf.readUInt32BE(4);
              } catch (e) {
                break;
              }
            }
            if (size <= 0) break;

            if (type === 'mvhd') {
              const mvhdBuf = Buffer.alloc(size - 8);
              try {
                fs.readSync(fd, mvhdBuf, 0, size - 8, innerOffset + 8);
                const version = mvhdBuf.readUInt8(0);
                let timescale = 0;
                let rawDuration = 0;

                if (version === 0) {
                  timescale = mvhdBuf.readUInt32BE(12);
                  rawDuration = mvhdBuf.readUInt32BE(16);
                } else if (version === 1) {
                  timescale = mvhdBuf.readUInt32BE(20);
                  rawDuration = mvhdBuf.readUInt32BE(28); 
                }

                if (timescale > 0) {
                  duration = rawDuration / timescale;
                }
              } catch (e) {
                // Ignore parsing errors for this specific box
              }
            } else if (type === 'trak') {
              const subEnd = innerOffset + size;
              let subOffset = innerOffset + 8;
              const subHeader = Buffer.alloc(8);
              while (subOffset < subEnd) {
                let subBytes = 0;
                try {
                  subBytes = fs.readSync(fd, subHeader, 0, 8, subOffset);
                } catch (e) {
                  break;
                }
                if (subBytes < 8) break;
                let subSize = subHeader.readUInt32BE(0);
                const subType = subHeader.toString('ascii', 4, 8);
                if (subSize === 1) {
                  const sizeBuf = Buffer.alloc(8);
                  try {
                    fs.readSync(fd, sizeBuf, 0, 8, subOffset + 8);
                    subSize = sizeBuf.readUInt32BE(4);
                  } catch (e) {
                    break;
                  }
                }
                if (subSize <= 0) break;

                if (subType === 'tkhd') {
                  try {
                    const tkhdBuf = Buffer.alloc(subSize - 8);
                    fs.readSync(fd, tkhdBuf, 0, subSize - 8, subOffset + 8);
                    const version = tkhdBuf.readUInt8(0);
                    
                    let widthOffset = 0;
                    if (version === 0) {
                      widthOffset = 76;
                    } else if (version === 1) {
                      widthOffset = 88;
                    }
                    
                    if (widthOffset > 0 && widthOffset + 8 <= tkhdBuf.length) {
                      const w = tkhdBuf.readUInt16BE(widthOffset);
                      const h = tkhdBuf.readUInt16BE(widthOffset + 4);
                      if (w > 0 && h > 0) {
                        width = w;
                        height = h;
                      }
                    }
                  } catch (e) {
                    // Ignore track header parsing errors
                  }
                }
                subOffset += subSize;
              }
            }

            innerOffset += size;
          }
        }

        readNextBox(0);

      } catch (err) {
        console.error('Try catch error during metadata parsing:', err);
        try { fs.closeSync(fd); } catch (e) {}
        resolve(buildResult(duration, width, height));
      }
    });
  });
}

function buildResult(duration, width, height) {
  let durStr = '00:00';
  if (duration !== null && !isNaN(duration)) {
    const hrs = Math.floor(duration / 3600);
    const mins = Math.floor((duration % 3600) / 60);
    const secs = Math.floor(duration % 60);
    const pad = (v) => String(v).padStart(2, '0');
    durStr = hrs > 0 ? `${pad(hrs)}:${pad(mins)}:${pad(secs)}` : `${pad(mins)}:${pad(secs)}`;
  } else {
    durStr = '00:10'; // Default fallback
  }

  let resStr = '1920x1080';
  let aspectStr = '16:9';
  if (width && height) {
    resStr = `${width}x${height}`;
    const gcd = (a, b) => (b === 0 ? a : gcd(b, a % b));
    const divisor = gcd(width, height);
    const aspectW = Math.round(width / divisor);
    const aspectH = Math.round(height / divisor);
    
    if (aspectW === 16 && aspectH === 9) {
      aspectStr = '16:9';
    } else if (aspectW === 9 && aspectH === 16) {
      aspectStr = '9:16';
    } else if (aspectW === 4 && aspectH === 3) {
      aspectStr = '4:3';
    } else if (aspectW === 3 && aspectH === 4) {
      aspectStr = '3:4';
    } else if (aspectW === 1 && aspectH === 1) {
      aspectStr = '1:1';
    } else {
      aspectStr = `${aspectW}:${aspectH}`;
    }
  }

  return {
    duration: durStr,
    resolution: resStr,
    aspect_ratio: aspectStr
  };
}

module.exports = { parseMp4Metadata };
