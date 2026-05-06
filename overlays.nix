final: prev: {
  # Disable chromaprint tests on Darwin: FFmpegAudioReaderTest.ReadRaw is OOM-killed
  # in the Nix sandbox (exit 137/SIGKILL) when building ffmpeg-full.
  # @upstream-issue TBD
  chromaprint = prev.chromaprint.overrideAttrs (
    _old:
    final.lib.optionalAttrs final.stdenv.hostPlatform.isDarwin {
      doCheck = false;
    }
  );

  # Disable kvazaar tests on Darwin: tests invoke ffmpeg to generate video
  # data and it is OOM-killed (exit 137/SIGKILL) in the Nix sandbox.
  # @upstream-issue https://github.com/NixOS/nixpkgs/issues/514347
  kvazaar = prev.kvazaar.overrideAttrs (
    _old:
    final.lib.optionalAttrs final.stdenv.hostPlatform.isDarwin {
      doCheck = false;
    }
  );
}
