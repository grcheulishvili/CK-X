# Corporate / custom root CA certificates

Drop your organisation's root CA here as one or more `.crt` files (PEM encoded),
then rebuild:

    docker compose up -d --build remote-desktop

Every `.crt` in this directory is installed into the desktop's system trust store
and registered with Firefox, which fixes the "SSL error / your connection is not
private" pages you get when a TLS-inspecting proxy re-signs traffic.

To export the CA your machine already trusts:

- **Windows**: certmgr.msc > Trusted Root Certification Authorities > find your
  company's CA > All Tasks > Export > Base-64 encoded X.509 (.CER) > rename to `.crt`
- **macOS**: Keychain Access > System Roots / System > export as `.pem`, rename to `.crt`
- **From a browser**: open any HTTPS page, click the padlock > connection details >
  view certificate > export the *root* of the chain

Nothing here is committed by default except this README, and no certificate is
required: without one the desktop simply uses the stock CA bundle.
