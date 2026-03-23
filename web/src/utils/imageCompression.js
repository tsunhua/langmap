/**
 * 压缩图片到指定宽度和质量
 * @param {File} file - 原始图片文件
 * @param {number} maxWidth - 最大宽度（默认 600px）
 * @param {number} quality - 质量 0-1（默认 0.7）
 * @returns {Promise<Blob>} 压缩后的 Blob
 */
export async function compressImage(file, maxWidth = 600, quality = 0.7) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        let { width, height } = img

        // 按比例缩放到 maxWidth
        if (width > maxWidth) {
          height = (height * maxWidth) / width
          width = maxWidth
        }

        canvas.width = width
        canvas.height = height

        const ctx = canvas.getContext('2d')
        ctx.fillStyle = '#FFFFFF'
        ctx.fillRect(0, 0, width, height)
        ctx.drawImage(img, 0, 0, width, height)

        // 转换为 WebP 格式
        canvas.toBlob(
          (blob) => {
            if (blob) {
              resolve(blob)
            } else {
              reject(new Error('压缩失败'))
            }
          },
          'image/webp',
          quality
        )
      } catch (error) {
        reject(error)
      }
    }
    img.onerror = () => reject(new Error('图片加载失败'))
    img.src = URL.createObjectURL(file)
  })
}

/**
 * 压缩图片直到小于指定大小
 * @param {File} file - 原始图片文件
 * @param {number} maxSize - 目标大小（字节）
 * @returns {Promise<{ blob: Blob, iterations: number }>} 压缩结果
 */
export async function compressToSize(file, maxSize = 100 * 1024) {
  let quality = 0.9
  let iterations = 0
  const maxIterations = 10

  while (iterations < maxIterations) {
    const blob = await compressImage(file, 600, quality)

    if (blob.size <= maxSize) {
      return { blob, iterations }
    }

    quality -= 0.1
    if (quality < 0.1) {
      break
    }

    iterations++
  }

  // 如果仍然太大，返回最后一次的结果
  const blob = await compressImage(file, 600, 0.6)
  return { blob, iterations }
}

/**
 * 验证图片文件
 * @param {File} file - 待验证的文件
 * @returns {Object} 验证结果 { valid: boolean, error?: string }
 */
export function validateImageFile(file) {
  const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']

  if (!validTypes.includes(file.type)) {
    return {
      valid: false,
      error: '仅支持 JPG、PNG、WebP 格式'
    }
  }

  const maxSize = 5 * 1024 * 1024 // 5MB
  if (file.size > maxSize) {
    return {
      valid: false,
      error: '图片大小不能超过 5MB'
    }
  }

  return { valid: true }
}
