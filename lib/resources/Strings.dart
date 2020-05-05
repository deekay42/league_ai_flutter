class Strings {
  static const String name = "League IQ";
  static const String buildRec = "The best item buy is:";
  static const String sub = "Subscribe";
  // static const List<String> instructions = ["1. Start your League IQ Desktop client",
  // "2. While in-game, sort your scoreboard (Press <Tab>) into this order: Top, Jg, Mid, Bot, Sup",
  // "3. Press Tab + F12 while in-game for the next recommendation, typically while channeling Back.",
  // "4. Remember: Recommendations change frequently as the game progresses. Check at least once before every back to avoid building outdated recommendations"
  // ];
  static const String probePing = "Desktop connection established";

static const List<String> instructions = ["1. Start your League IQ Desktop client", "2. Press Tab + F12 while in game"];
static const List<String> instructionsDesktop = ["1. Start your League IQ app on your phone", "2. Press Tab + F12 while in game"];

  // static const List<String> instructionsDesktop = ["1. Start the League IQ Desktop App, then the mobile app, then a new game of League of Legends.",
  // "2. If you have a second monitor drag the League IQ Desktop App window on your second screen so the game does not cover it",
  // "3. While in-game, sort your scoreboard (Press <Tab>) into this order: Top, Jg, Mid, Bot, Sup",
  // "4. Press Tab + F12 while in-game for the next recommendation, typically while backing.",
  // "5. Remember: Recommendations change frequently as the game progresses. Check at least once before every back to avoid building outdated recommendations"
  // ];
  static const String mobileWelcome = "Welcome to League IQ! Download the windows app at http://leagueiq.gg and scan the QR code to complete the pairing.";
  static const String desktopWelcome = "Welcome to League IQ! Please download the League IQ mobile app at http://leagueiq.gg or in the App Store or Play Store. Then pair your phone by scanning the QR Code below with your League IQ app.";
  static const String IOS_adMobAppId = "ca-app-pub-4748256700093905~2059247399";
  static const String ANDROID_adMobAppId = "ca-app-pub-4748256700093905~1589341358";

  static const String IOS_adMobAdUnitId = "ca-app-pub-4748256700093905/4823520849";
  static const String ANDROID_adMobAdUnitId = "ca-app-pub-4748256700093905/4643660356";


  static const String remaining = "You have N recommendations remaining today";

  static const String outOfPredictions = "You used all your recommendations for today :(\n Buy me a cup of coffee for unlimited recommendations :)";


  static const List<List<String>> pitch = [
  ["Full access",
  "Unlimited recommendations, no ads, max visibility"]
,
  ["Best next item in any situation",
  "Recommendations are dynamic based on your champ, team composition, itemization and enemy team"]
,
  ["Real-time, in-game",
  "No more memorizing static build-paths that don't apply to the game situation and are outdated after 14 days."]
,
  ["Trained by the best",
  "Powerful AI trained with millions of game situations by Korean grandmasters"]
,
  ["Always up to date",
  "Constantly updated to the latest meta as new patches are released"]
  ];

  static const String sub_price = "Subscribe \$4.99";
  static const String membership_title = "Premium Membership";
  static const String price = "\$4.99/month";
  static const String change = ">";
  static const String fineprint =
      "Bla bla bla legal bla bla bla legal blablabla";

  static const String clientTokenError = "Unable to obtain payment token. Please try again later.";
  static const String nonceError = "Unable to obtain payment nonce. Please try again later.";
  static const String checkoutError = "Unable to complete checkout. Please try again later.";
  static const String generalPaymentsError = "Unknown error. Please try again later.";

  static const String version = "0.0.1";
}
