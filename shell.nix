{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nixpkgs-fmt
    mkpasswd
    rage
  ];
}
