{
  description = "A Simple Lean to WASM/EMScripten project";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.lean-wasm.url = "https://github.com/leanprover/lean4-nightly/releases/download/nightly-2024-03-30/lean-4.8.0-nightly-2024-03-30-linux_wasm32.tar.zst";
  inputs.lean-wasm.flake = false;

  outputs = { self, nixpkgs, lean-wasm,  flake-utils }: flake-utils.lib.eachDefaultSystem (system:
  let
      pkgs = nixpkgs.legacyPackages.${system};
      js = pkgs.stdenv.mkDerivation {
        name = "MyWasmProject";
        buildInputs = [ pkgs.emscripten ];
        src = ./.;
        buildPhase = ''
        mkdir $out mkdir .emscriptencache
        export EM_CACHE=.emscriptencache
        emcc -o $out/main.js \
          -I${lean-wasm}/include/ \
          -L${lean-wasm}/lib/lean/ \
          $(find . -name "*.c") \
          -lInit -lLean -lleancpp -lleanrt -sFORCE_FILESYSTEM -lnodefs.js \
          -s EXIT_RUNTIME=0 -s MAIN_MODULE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s ALLOW_MEMORY_GROWTH=1 \
          -fwasm-exceptions -pthread -flto
        '';
      };
    in {
      defaultPackage = js;
    });
}
