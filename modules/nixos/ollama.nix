{ pkgs, inputs, ... }:
 
{
  services.ollama = {
    enable = true;
    loadModels = [
      "llama3.1:8b"
      "starcoder2:3b"
    ];
  };
}