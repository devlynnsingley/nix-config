self: pkgs:

let ledgerPkg = import ~/src/ledger;
    ledger = ledgerPkg.packages.${pkgs.system}.ledger; in

{

ledger_HEAD = ledger.overrideAttrs (attrs: {
  doCheck = false;

  preConfigure = (attrs.preConfigure or "") + ''
    sed -i -e "s%DESTINATION \\\''${Python_SITEARCH}%DESTINATION "$out/lib/python27/site-packages"%" src/CMakeLists.txt
  '';

  preInstall = (attrs.preInstall or "") + ''
    mkdir -p $out/lib/python27/site-packages
  '';
});

ledger_HEAD_python3 = ledger.overrideAttrs (attrs: {
  boost = pkgs.boost.override { python = pkgs.python3; };

  preConfigure = ''
    sed -i -e "s%DESTINATION \\\''${Python_SITEARCH}%DESTINATION $out/lib/python37/site-packages%" src/CMakeLists.txt
  '';

  preInstall = ''
    mkdir -p $out/lib/python37/site-packages
  '';
});

ledgerPy3Env = pkgs.myEnvFun {
  name = "ledger-py3";
  buildInputs = with pkgs; [
    cmake (pkgs.boost.override { python = pkgs.python3; }) gmp mpfr libedit
    python3 texinfo gnused ninja clang doxygen
  ];
};

ledgerPy2Env = pkgs.myEnvFun {
  name = "ledger-py2";
  buildInputs = with pkgs; [
    cmake boost gmp mpfr libedit python texinfo gnused ninja clang doxygen
  ];
};

}
