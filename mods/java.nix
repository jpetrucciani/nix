final: prev: {
  stinkyJdk = { java ? final.zulu, name ? "stinky-jdk-${java.version}", certFiles ? [ ] }:
    let
      jdkWithCerts = final.runCommand name
        {
          buildInputs = [ java ];
        }
        ''
          mkdir -p $out
          cp ${java}/lib/security/cacerts $out/cacerts
          chmod +w $out/cacerts

          for cert in ${builtins.concatStringsSep " " certFiles}; do
            echo "Importing: $cert"
            ${java}/bin/keytool \
              -importcert \
              -noprompt \
              -trustcacerts \
              -storepass changeit \
              -alias "company-$(basename $cert | tr ' ' '-' | tr -d '.crt')" \
              -file "$cert" \
              -keystore $out/cacerts
          done

          cp -r ${java}/* $out/
          chmod +w $out/lib/security
          chmod +w $out/lib/security/cacerts
          rm -f $out/lib/security/cacerts
          cp $out/cacerts $out/lib/security/cacerts

          chmod 644 $out/lib/security/cacerts
        '';
      JAVA_HOME = jdkWithCerts;
    in
    jdkWithCerts // {
      env = {
        inherit JAVA_HOME;
      };
    };
}
