import apiClient from './client.js'

/**
 * 直接上传图片到 Worker
 * @param {Blob} blob - 图片 Blob
 * @returns {Promise<string>} 公开访问的图片 URL
 */
export async function uploadImage(blob) {
  const formData = new FormData()
  formData.append('image_file', blob)

  const token = localStorage.getItem('authToken')

  const response = await fetch('/api/v1/images/upload', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
      // 不要设置 Content-Type，让浏览器自动设置 multipart/form-data
    },
    body: formData
  })

  const data = await response.json()

  if (!data.success) {
    throw new Error(data.error || data.message || '上传失败')
  }

  return data.data.image_url
}
