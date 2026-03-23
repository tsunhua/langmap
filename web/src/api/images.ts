import apiClient from './client.js'

/**
 * 获取预签名 URL 并上传图片
 * @param {Blob} blob - 图片 Blob
 * @returns {Promise<string>} 公开访问的图片 URL
 */
export async function uploadPresignedUrl(blob) {
  // 1. 获取预签名 URL
  const presignResponse = await apiClient.post('/images/upload-presign', {
    content_type: blob.type,
    content_length: blob.size
  })

  const { upload_url, image_url } = presignResponse.data

  // 2. 直接上传到 R2
  const uploadResponse = await fetch(upload_url, {
    method: 'PUT',
    body: blob,
    headers: {
      'Content-Type': blob.type
    }
  })

  if (!uploadResponse.ok) {
    throw new Error('上传失败')
  }

  return image_url
}
