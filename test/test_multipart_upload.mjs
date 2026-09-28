#!/usr/bin/env node
// MultipartUpload（app/javascript/multipart_upload.js）のテスト
// サーバー（MultipartUploadsController）と S3 の応答を偽の fetch で再現する
import assert from "node:assert/strict"
import crypto from "node:crypto"
import { MultipartUpload } from "../app/javascript/multipart_upload.js"

// 偽のサーバーと S3。failPart に指定したパートは failTimes 回だけ失敗させる
function fakeBackend({ partSize, byteSize, failPart = null, failTimes = 0 }) {
  const calls = { partUrls: [], puts: {}, complete: null, cancel: 0 }
  const partCount = Math.ceil(byteSize / partSize)
  const json = (status, body) => ({ ok: status < 300, status, json: async () => body, headers: new Map() })

  const fetchImpl = async (url, options) => {
    if (url.startsWith("https://s3.example/")) {
      const partNumber = Number(new URL(url).searchParams.get("partNumber"))
      calls.puts[partNumber] = (calls.puts[partNumber] || 0) + 1
      if (partNumber === failPart && calls.puts[partNumber] <= failTimes) {
        return { ok: false, status: 500, headers: new Map() }
      }
      return { ok: true, status: 200, headers: new Map([ [ "ETag", `"etag-${partNumber}"` ] ]) }
    }

    const body = JSON.parse(options.body)
    switch (url) {
      case "/multipart_uploads":
        return json(200, { token: "token-1", part_size: partSize, part_count: partCount })
      case "/multipart_uploads/part_urls":
        calls.partUrls.push(body.part_numbers)
        return json(200, { urls: Object.fromEntries(body.part_numbers.map((n) => [ n, `https://s3.example/?partNumber=${n}` ])) })
      case "/multipart_uploads/complete":
        calls.complete = body
        return json(200, { signed_id: "signed-1" })
      case "/multipart_uploads/cancel":
        calls.cancel += 1
        return { ok: true, status: 204, headers: new Map() }
    }
    throw new Error(`unexpected request: ${url}`)
  }
  return { calls, fetchImpl }
}

function makeFile(byteSize) {
  const bytes = crypto.randomBytes(byteSize)
  return { file: new File([ bytes ], "movie.mp4", { type: "video/mp4" }), md5: crypto.createHash("md5").update(bytes).digest("base64") }
}

const tests = {
  async "全パートを送り、ファイル全体のMD5とETagで完了すること"() {
    const { file, md5 } = makeFile(2500)
    const { calls, fetchImpl } = fakeBackend({ partSize: 1000, byteSize: 2500 })
    const progress = []

    const signedId = await new MultipartUpload(file, { fetchImpl, onProgress: (loaded) => progress.push(loaded) }).start()

    assert.equal(signedId, "signed-1")
    assert.equal(calls.complete.checksum, md5)
    assert.deepEqual(calls.complete.parts.map((p) => p.part_number).sort(), [ 1, 2, 3 ])
    assert.deepEqual(calls.complete.parts.find((p) => p.part_number === 3).etag, '"etag-3"')
    assert.equal(progress.at(-1), 2500)
  },

  async "署名付きURLをまとめて取得すること"() {
    const { file } = makeFile(45)
    const { calls, fetchImpl } = fakeBackend({ partSize: 1, byteSize: 45 })

    await new MultipartUpload(file, { fetchImpl }).start()

    assert.deepEqual(calls.partUrls.map((numbers) => numbers.length), [ 20, 20, 5 ])
  },

  async "パートの送信に失敗しても再試行して完了すること"() {
    const { file } = makeFile(3000)
    const { calls, fetchImpl } = fakeBackend({ partSize: 1000, byteSize: 3000, failPart: 2, failTimes: 1 })

    const signedId = await new MultipartUpload(file, { fetchImpl }).start()

    assert.equal(signedId, "signed-1")
    assert.equal(calls.puts[2], 2)
    assert.equal(calls.cancel, 0)
  },

  async "失敗が続いた場合は分割アップロードを中止してエラーにすること"() {
    const { file } = makeFile(3000)
    const { calls, fetchImpl } = fakeBackend({ partSize: 1000, byteSize: 3000, failPart: 2, failTimes: 99 })

    await assert.rejects(new MultipartUpload(file, { fetchImpl }).start(), /HTTP 500/)

    assert.equal(calls.cancel, 1)
    assert.equal(calls.complete, null)
  }
}

// 再試行の待ち時間を短くする
const realSetTimeout = globalThis.setTimeout
globalThis.setTimeout = (fn) => realSetTimeout(fn, 0)

let failed = 0
for (const [ name, test ] of Object.entries(tests)) {
  try {
    await test()
    console.log(`✓ ${name}`)
  } catch (error) {
    failed += 1
    console.error(`✗ ${name}\n  ${error.stack}`)
  }
}
console.log(`\n${Object.keys(tests).length - failed}/${Object.keys(tests).length} passed`)
process.exit(failed ? 1 : 0)
