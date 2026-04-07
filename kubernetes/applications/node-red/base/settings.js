/**
 * This is the default settings file provided by Node-RED.
 *
 * It can contain any valid JavaScript code that will get run when Node-RED
 * is started.
 *
 * Lines that start with // are commented out.
 * Each entry should be separated from the entries above and below by a comma ','
 *
 * For more information about individual settings, refer to the documentation:
 *    https://nodered.org/docs/user-guide/runtime/configuration
 *
 * The settings are split into the following sections:
 *  - Flow File and User Directory Settings
 *  - Security
 *  - Server Settings
 *  - Runtime Settings
 *  - Editor Settings
 *  - Node Settings
 *
 **/

module.exports = {
  /*******************************************************************************
   * Flow File and User Directory Settings
   *  - flowFile
   *  - credentialSecret
   *  - flowFilePretty
   *  - userDir
   *  - nodesDir
   ******************************************************************************/

  /** The file containing the flows. If not set, defaults to flows_<hostname>.json **/
  flowFile: "flows.json",

  /** Credential encryption key is injected via the NODE_RED_CREDENTIAL_SECRET
   * environment variable (sourced from the node-red-credentials K8s Secret).
   * Note: once set, do not change it — doing so will prevent Node-RED from
   * decrypting existing credentials and they will be lost.
   */
  credentialSecret: process.env.NODE_RED_CREDENTIAL_SECRET,

  /** By default, the flow JSON will be formatted over multiple lines making
   * it easier to compare changes when using version control.
   * To disable pretty-printing of the JSON set the following property to false.
   */
  flowFilePretty: true,

  /*******************************************************************************
   * Security
   *  - adminAuth
   ******************************************************************************/

  adminAuth: {
    type: "strategy",
    strategy: {
      name: "openidconnect",
      label: "Sign in with Authentik",
      icon: "fa-cloud",
      strategy: require("passport-openidconnect").Strategy,
      options: {
        issuer: process.env.AUTHENTIK_HOST + "/application/o/node-red/",
        authorizationURL:
          process.env.AUTHENTIK_HOST + "/application/o/authorize/",
        tokenURL: process.env.AUTHENTIK_HOST + "/application/o/token/",
        userInfoURL: process.env.AUTHENTIK_HOST + "/application/o/userinfo/",
        clientID: "node-red",
        clientSecret: process.env.NODE_RED_OIDC_CLIENT_SECRET,
        callbackURL: process.env.NODE_RED_CALLBACK_URL,
        scope: ["email", "profile", "openid"],
        verify: function (_context, _issuer, profile, done) {
          return done(null, profile);
        },
      },
    },
    users: function (user) {
      return Promise.resolve({ username: user, permissions: "*" });
    },
  },

  /*******************************************************************************
   * Server Settings
   ******************************************************************************/

  /** the tcp port that the Node-RED web server is listening on */
  uiPort: process.env.PORT || 1880,

  /*******************************************************************************
   * Runtime Settings
   ******************************************************************************/

  /** Configure the logging output */
  logging: {
    console: {
      level: "info",
      metrics: false,
      audit: false,
    },
  },

  exportGlobalContextKeys: false,

  externalModules: {},

  /*******************************************************************************
   * Editor Settings
   ******************************************************************************/

  editorTheme: {
    palette: {},

    projects: {
      enabled: false,
      workflow: {
        mode: "manual",
      },
    },

    codeEditor: {
      lib: "ace",
      options: {
        theme: "vs",
      },
    },
  },

  /*******************************************************************************
   * Node Settings
   ******************************************************************************/

  /** Allow the Function node to load additional npm modules directly */
  functionExternalModules: true,

  functionGlobalContext: {},

  debugMaxLength: 1000,

  mqttReconnectTime: 15000,

  serialReconnectTime: 15000,
};
