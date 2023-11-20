{
  description = "My Lean package";

  inputs.lean.url = "github:leanprover/lean4";
  inputs.std4.url = "github:leanprover/std4";
  inputs.std4.flake = false;
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.lean-wasm.url = "https://github.com/leanprover/lean4-nightly/releases/download/nightly-2023-11-20/lean-4.4.0-nightly-2023-11-20-linux_wasm32.tar.zst";
  inputs.lean-wasm.flake = false;

  outputs = { self, nixpkgs, lean, lean-wasm, std4, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
  let
      pkgs = nixpkgs.legacyPackages.${system};
      leanPkgs = lean.packages.${system};
      std = leanPkgs.buildLeanPackage {
        name = "Std";
        src = "${std4}/";
      };
      myPkg = leanPkgs.buildLeanPackage {
        name = "MyPackage";  # must match the name of the top-level .lean file
        src = ./.;
        deps = [ std ];
      };
      js = pkgs.stdenv.mkDerivation {
        name = "MyPackage-wasm";
        buildInputs = [ pkgs.emscripten ];
        src = myPkg.cTree;
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
      packages = myPkg // {
        inherit (leanPkgs) lean;
        inherit js;
      };

      templates.default = {
        path = ./.;
        description = "A minimal lean WASM project";
      };

      devShell = myPkg.devShell.overrideAttrs (o : {
        buildInputs = o.buildInputs ++ [ leanPkgs.lean-dev ];
      });
    });
}
