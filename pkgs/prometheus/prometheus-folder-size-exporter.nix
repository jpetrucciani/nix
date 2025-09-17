# [prometheus-folder-size-exporter](https://github.com/MindFlavor/prometheus_folder_size_exporter) is a prometheus exporter for directory sizes
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "prometheus-folder-size-exporter";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "MindFlavor";
    repo = "prometheus_folder_size_exporter";
    rev = version;
    hash = "sha256-G1oWGiTyftloPxgOuiYFO7hofHdbwPCG4QDXK1t5qWk=";
  };

  postPatch = ''
    # patch to use gauge instead of counter
    # from https://github.com/MindFlavor/prometheus_folder_size_exporter/pull/18/files
    sed -i -E 's/(MetricType::)Counter/\1Gauge/g' ./src/main.rs
  '';

  cargoHash = "sha256-IjhNtUgeWr4WjioAZoA1dkQrkTdaSprXXmF15l06rSA=";

  meta = with lib; {
    description = "A Rust only folder size exporter for Prometheus (Grafana";
    homepage = "https://github.com/MindFlavor/prometheus_folder_size_exporter";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "prometheus_folder_size_exporter";
  };
}
