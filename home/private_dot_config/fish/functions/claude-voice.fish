function claude-voice --description "Launch Claude Code with local STT (faster-whisper on GPU)"
    VOICE_STREAM_BASE_URL=ws://localhost:8766 claude $argv
end
