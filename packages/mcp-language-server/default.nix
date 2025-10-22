{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-language-server";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "isaacphi";
    repo = "mcp-language-server";
    rev = "main";
    hash = "sha256-INyzT/8UyJfg1PW5+PqZkIy/MZrDYykql0rD2Sl97Gg=";
  };

  vendorHash = "sha256-WcYKtM8r9xALx68VvgRabMPq8XnubhTj6NAdtmaPa+g=";

  subPackages = ["."];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "An MCP server that runs and exposes a language server to LLMs";
    homepage = "https://github.com/isaacphi/mcp-language-server";
    license = licenses.bsd3;
    maintainers = [];
    mainProgram = "mcp-language-server";
  };
}
