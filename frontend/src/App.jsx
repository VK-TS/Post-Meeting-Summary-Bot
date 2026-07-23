import { useState } from 'react'
import './App.css'

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
const API_URL = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '')
const MAX_POLLS = 3600

function App() {
  const [file, setFile] = useState(null)
  const [recipientEmail, setRecipientEmail] = useState('')
  const [speakerEmails, setSpeakerEmails] = useState('')
  const [speakerNames, setSpeakerNames] = useState('')
  const [sendMode, setSendMode] = useState('all')
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [jobId, setJobId] = useState(null)
  const [exportJobId, setExportJobId] = useState(null)
  const [stage, setStage] = useState('')
  const [progress, setProgress] = useState('')

  const handleFileChange = (e) => {
    setFile(e.target.files[0])
  }

  const downloadExport = (type) => {
    window.location.href = `${API_URL}/job/${exportJobId}/export/${type}`
  }

  const pollJob = async (id) => {
    for (let attempt = 0; attempt < MAX_POLLS; attempt += 1) {
      const response = await fetch(`${API_URL}/job/${id}`)
      const data = await response.json()
      setStage(data.stage || '')
      setProgress(data.total ? `${data.current}/${data.total}` : '')

      if (data.status === 'done') {
        setResult(data.result)
        setExportJobId(id)
        setJobId(null)
        return
      }

      if (data.status === 'not_found') {
        setError('Job not found')
        setJobId(null)
        return
      }

      if (data.status === 'failed') {
        setError(data.error || 'Processing failed')
        setJobId(null)
        return
      }

      await sleep(2000)
    }
    setError('Processing timed out after 2 hours')
    setJobId(null)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!file) return

    setLoading(true)
    setError(null)
    setResult(null)
    setExportJobId(null)
    setStage('')
    setProgress('')

    const formData = new FormData()
    formData.append('file', file)
    formData.append('recipient_email', recipientEmail)
    formData.append('speaker_emails', speakerEmails)
    formData.append('speaker_names', speakerNames)
    formData.append('send_mode', sendMode)

    try {
      const response = await fetch(`${API_URL}/process-call`, {
        method: 'POST',
        body: formData,
      })

      if (!response.ok) {
        throw new Error('Failed to process the call')
      }

      const data = await response.json()
      if (!data.job_id) {
        throw new Error(data.error || 'No job id returned')
      }

      setJobId(data.job_id)
      await pollJob(data.job_id)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app">
      <header>
        <h1>Post-Meeting Summary Bot</h1>
        <p>Upload an audio file to get transcript, summary, and speaker feedback</p>
      </header>

      <main>
        <form onSubmit={handleSubmit} className="upload-form">
          <input
            type="file"
            accept="audio/*"
            onChange={handleFileChange}
            required
          />

          <input
            type="email"
            value={recipientEmail}
            onChange={(e) => setRecipientEmail(e.target.value)}
            placeholder="General recipient email"
          />

          <textarea
            value={speakerEmails}
            onChange={(e) => setSpeakerEmails(e.target.value)}
            placeholder="Speaker email mapping (one per line): SPEAKER_00: alice@example.com"
            rows={4}
          />

          <textarea
            value={speakerNames}
            onChange={(e) => setSpeakerNames(e.target.value)}
            placeholder="Speaker name mapping (one per line): SPEAKER_00: Alice"
            rows={3}
          />

          <div className="radio-group">
            <label>
              <input
                type="radio"
                value="all"
                checked={sendMode === 'all'}
                onChange={(e) => setSendMode(e.target.value)}
              />
              Send all feedback to general email
            </label>
            <label>
              <input
                type="radio"
                value="per_speaker"
                checked={sendMode === 'per_speaker'}
                onChange={(e) => setSendMode(e.target.value)}
              />
              Send only speaker feedback to respective speaker emails
            </label>
          </div>

          <button type="submit" disabled={loading}>
            {loading ? 'Processing...' : 'Process Call'}
          </button>
        </form>

        {jobId && <div className="error">Processing job: {jobId}</div>}
        {stage && (
          <div className="error">
            {stage}{progress && ` ${progress}`}
          </div>
        )}
        {error && <div className="error">{error}</div>}

        {result && (
          <div className="results">
            <div className="export-actions">
              <button type="button" onClick={() => downloadExport('pdf')}>Download PDF</button>
              <button type="button" onClick={() => downloadExport('docx')}>Download DOCX</button>
            </div>

            <h2>Transcript</h2>
            <p>{result.transcript}</p>

            <h2>Summary</h2>
            <p>{result.summary}</p>

            <h2>Coaching Feedback</h2>
            <p>{result.feedback}</p>

            {result.speaker_feedback && (
              <div className="speaker-feedback">
                <h2>Speaker Feedback</h2>
                {Object.entries(result.speaker_feedback).map(([speaker, text]) => (
                  <div key={speaker} className="speaker-item">
                    <h3>{speaker}</h3>
                    <p>{text}</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  )
}

export default App
