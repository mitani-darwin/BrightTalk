// 大きなファイルを S3 へ分割アップロード（multipart upload）する
// サーバー（MultipartUploadsController）から各パートの署名付き URL を受け取り、S3 へ直接 PUT する
// Active Storage の blob に必要なファイル全体の MD5 は、パートを順に読みながら計算する
import SparkMD5 from "spark-md5"

const CONCURRENCY = 4
const PART_URL_BATCH = 20
const MAX_RETRIES = 3

export class MultipartUpload {
  constructor(file, { basePath = "/multipart_uploads", onProgress = () => {}, fetchImpl = globalThis.fetch.bind(globalThis) } = {}) {
    this.file = file
    this.basePath = basePath
    this.onProgress = onProgress
    this.fetch = fetchImpl
    this.token = null
    this.uploadedBytes = 0
  }

  // アップロードして blob の signed_id を返す。失敗したら S3 側の分割アップロードを中止する
  async start() {
    const started = await this.post("", {
      filename: this.file.name,
      content_type: this.file.type || "application/octet-stream",
      byte_size: this.file.size
    })
    this.token = started.token

    try {
      const { parts, checksum } = await this.uploadParts(started.part_size, started.part_count)
      const completed = await this.post("/complete", { token: this.token, parts, checksum })
      return completed.signed_id
    } catch (error) {
      await this.cancel()
      throw error
    }
  }

  async cancel() {
    if (!this.token) return
    try {
      await this.post("/cancel", { token: this.token })
    } catch (error) {
      console.warn("分割アップロードの中止に失敗しました", error)
    }
  }

  // MD5 はパート順に計算する必要があるため読み込みは順番に行い、S3 への送信だけを並行させる
  async uploadParts(partSize, partCount) {
    const md5 = new SparkMD5.ArrayBuffer()
    const parts = []
    const inFlight = new Set()
    let urls = {}
    let failure = null

    for (let partNumber = 1; partNumber <= partCount; partNumber++) {
      if (failure) break

      if (!urls[partNumber]) {
        const numbers = []
        for (let n = partNumber; n <= Math.min(partCount, partNumber + PART_URL_BATCH - 1); n++) numbers.push(n)
        urls = (await this.post("/part_urls", { token: this.token, part_numbers: numbers })).urls
      }

      const chunk = this.file.slice((partNumber - 1) * partSize, Math.min(partNumber * partSize, this.file.size))
      md5.append(await chunk.arrayBuffer())

      const url = urls[partNumber]
      const task = this.uploadPart(url, chunk)
        .then((etag) => { parts.push({ part_number: partNumber, etag }) })
        .catch((error) => { failure = failure || error })
        .finally(() => inFlight.delete(task))
      inFlight.add(task)

      if (inFlight.size >= CONCURRENCY) await Promise.race(inFlight)
    }

    await Promise.all(inFlight)
    if (failure) throw failure

    return { parts, checksum: btoa(md5.end(true)) }
  }

  async uploadPart(url, chunk) {
    for (let attempt = 1; ; attempt++) {
      try {
        const response = await this.fetch(url, { method: "PUT", body: chunk })
        if (!response.ok) throw new Error(`パートのアップロードに失敗しました (HTTP ${response.status})`)

        const etag = response.headers.get("ETag")
        if (!etag) throw new Error("ETag を取得できませんでした（S3 の CORS で ETag を公開してください）")

        this.uploadedBytes += chunk.size
        this.onProgress(this.uploadedBytes, this.file.size)
        return etag
      } catch (error) {
        if (attempt >= MAX_RETRIES) throw error
        await new Promise((resolve) => setTimeout(resolve, 1000 * attempt))
      }
    }
  }

  async post(path, body) {
    const response = await this.fetch(`${this.basePath}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken() },
      credentials: "same-origin",
      body: JSON.stringify(body)
    })
    const data = response.status === 204 ? {} : await response.json().catch(() => ({}))
    if (!response.ok) {
      const error = new Error(data.error || `分割アップロードに失敗しました (HTTP ${response.status})`)
      error.status = response.status
      throw error
    }
    return data
  }
}

function csrfToken() {
  return globalThis.document?.querySelector('meta[name="csrf-token"]')?.content || ""
}
