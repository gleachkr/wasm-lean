{
  description = "Template source for lean-wasm";

  outputs = { self }: {

    defaultTemplate = {
      path = ./project;
      description = "A minimal lean WASM project";
    };

  };
}
