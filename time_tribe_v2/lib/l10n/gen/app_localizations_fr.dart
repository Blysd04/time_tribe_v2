// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Enregistrer';

  @override
  String get saved => 'Enregistré';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get share => 'Partager';

  @override
  String get copy => 'Copier';

  @override
  String get create => 'Créer';

  @override
  String get add => 'Ajouter';

  @override
  String get done => 'Terminé';

  @override
  String get hide => 'Masquer';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get selected => 'Sélectionné';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get menu => 'Menu';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get you => 'Vous';

  @override
  String get busy => 'Occupé';

  @override
  String get free => 'Libre';

  @override
  String get linkCopied => 'Lien copié !';

  @override
  String get weekdaysShort => 'Lun,Mar,Mer,Jeu,Ven,Sam,Dim';

  @override
  String get weekdaysLong =>
      'Lundi,Mardi,Mercredi,Jeudi,Vendredi,Samedi,Dimanche';

  @override
  String monthYearFormat(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get monthView => 'Vue mensuelle';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'il y a $n minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'il y a $n heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'il y a $n jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get home => 'Accueil';

  @override
  String get profile => 'Profil';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Paramètres';

  @override
  String get personalSchedule => 'Mon planning';

  @override
  String get tribes => 'Tribus';

  @override
  String get templates => 'Modèles';

  @override
  String get workspace => 'Espace';

  @override
  String get workspaceSubtitle => 'Gérez votre emploi du temps';

  @override
  String get appTagline => 'Organisez votre temps, ensemble';

  @override
  String get emailOrUsernameHint => 'E-mail ou nom d\'utilisateur';

  @override
  String get passwordHint => 'Mot de passe';

  @override
  String get confirmPasswordHint => 'Confirmer le mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get login => 'Se connecter';

  @override
  String get loginWithGoogle => 'Continuer avec Google';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get register => 'S\'inscrire';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createAccountSubtitle => 'Ça prend moins d\'une minute';

  @override
  String get displayName => 'Nom d\'affichage';

  @override
  String get email => 'E-mail';

  @override
  String get registerSuccess => 'Compte créé ! Connectez-vous.';

  @override
  String get errorIdentifierRequired =>
      'Saisissez votre e-mail ou nom d\'utilisateur';

  @override
  String get errorPasswordRequired => 'Saisissez votre mot de passe';

  @override
  String get errorWrongCredentials => 'Identifiant ou mot de passe incorrect';

  @override
  String get errorDisplayNameRequired => 'Saisissez un nom';

  @override
  String get errorEmailRequired => 'Saisissez votre e-mail';

  @override
  String get errorEmailInvalid => 'Cet e-mail n\'est pas valide';

  @override
  String get errorCreatePassword => 'Créez un mot de passe';

  @override
  String get errorPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get regionTimezone => 'Région et fuseau horaire';

  @override
  String editField(String field) {
    return 'Modifier : $field';
  }

  @override
  String get confirmSaveTitle => 'Enregistrer les modifications ?';

  @override
  String get confirmSaveMessage =>
      'Voulez-vous enregistrer cette modification ?';

  @override
  String get confirmSaveTimezone =>
      'Voulez-vous enregistrer ce fuseau horaire ?';

  @override
  String followDevice(String tz) {
    return 'Appareil · $tz';
  }

  @override
  String get autoTimezone => 'Utiliser le fuseau de l\'appareil';

  @override
  String get country => 'Pays';

  @override
  String get chooseCountry => 'Choisir un pays';

  @override
  String get city => 'Ville';

  @override
  String get cityHint => '(avec fuseau horaire)';

  @override
  String get chooseCity => 'Choisir une ville';

  @override
  String get errorPickCountryCity => 'Choisissez un pays et une ville';

  @override
  String get timezoneExplanation =>
      'Toutes les heures de l\'app (planning, tribus, notifications) s\'affichent dans ce fuseau. Vos amis à l\'étranger voient leur heure locale.';

  @override
  String countryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'vn': 'Viêt Nam',
      'ca': 'Canada',
      'jp': 'Japon',
      'kr': 'Corée du Sud',
      'gb': 'Royaume-Uni',
      'fr': 'France',
      'us': 'États-Unis',
      'au': 'Australie',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get account => 'Compte';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirm => 'Voulez-vous vous déconnecter ?';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle =>
      'Supprimer définitivement votre compte et vos données';

  @override
  String get deleteAccountWarningTitle => 'Cette action est irréversible';

  @override
  String get deleteConsequence1 =>
      'Tous vos plannings et modèles seront supprimés.';

  @override
  String get deleteConsequence2 =>
      'Vous quitterez toutes vos tribus. Celles que vous dirigez seront confiées à la personne suivante.';

  @override
  String get deleteConsequence3 =>
      'Vous ne pourrez plus vous connecter avec ce compte.';

  @override
  String get tribesYouLead => 'Tribus que vous dirigez';

  @override
  String leadershipGoesTo(String tribe, String name) {
    return '$tribe : $name deviendra chef';
  }

  @override
  String tribeWillBeDissolved(String tribe) {
    return '$tribe : vous êtes seul(e), la tribu sera dissoute';
  }

  @override
  String get deleteReasonTitle => 'Pourquoi partez-vous ?';

  @override
  String get reasonNotUsing => 'Je ne l\'utilise plus';

  @override
  String get reasonOtherApp => 'J\'ai trouvé une autre app';

  @override
  String get reasonPrivacy => 'Je suis inquiet(e) pour ma vie privée';

  @override
  String get reasonOther => 'Autre raison';

  @override
  String get reasonOtherHint => 'Dites-nous en plus...';

  @override
  String get deleteUnderstand => 'Je comprends que c\'est irréversible';

  @override
  String get deleteAccountPermanently => 'Supprimer mon compte';

  @override
  String get deleteAccountHint =>
      'Choisissez une raison et cochez la case pour continuer.';

  @override
  String get deleteAccountFinalTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountFinalMessage =>
      'Dernière étape. Vos données ne pourront pas être récupérées.';

  @override
  String get accountDeleted => 'Votre compte a été supprimé. À bientôt !';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterPersonal => 'Personnel';

  @override
  String get filterGroup => 'Tribus';

  @override
  String get last30Days => 'Notifications des 30 derniers jours';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String nTitleNewBlock(String task) {
    return 'Nouvelle activité : $task';
  }

  @override
  String nTitleBlockUpdated(String task) {
    return 'Mise à jour : $task';
  }

  @override
  String nTitleBlockRescheduled(String task) {
    return 'Horaire modifié : $task';
  }

  @override
  String get nTitleBlockCancelled => 'Activité annulée';

  @override
  String get nTitleResponseAccepted => 'Quelqu\'un participe';

  @override
  String get nTitleResponseDeclined => 'Quelqu\'un ne participe pas';

  @override
  String get nTitleMemberJoined => 'Nouveau membre';

  @override
  String get nTitleMemberLeft => 'Un membre est parti';

  @override
  String get nTitleKicked => 'Vous avez été retiré(e) d\'une tribu';

  @override
  String get nTitleRenamed => 'Tribu renommée';

  @override
  String get nTitleDissolved => 'Tribu dissoute';

  @override
  String get nTitleRoleChanged => 'Rôle modifié';

  @override
  String get nTitlePersonalAdded => 'Nouvelle activité personnelle';

  @override
  String nBodyNewBlock(String actor, String tribe) {
    return '$actor a ajouté une activité à $tribe. Vous participez ?';
  }

  @override
  String nBodyBlockUpdated(String actor) {
    return '$actor a mis à jour l\'activité.';
  }

  @override
  String nBodyBlockRescheduled(String actor) {
    return '$actor a changé l\'horaire, merci de reconfirmer.';
  }

  @override
  String nBodyBlockCancelled(String actor, String task, String tribe) {
    return '$actor a annulé « $task » dans $tribe.';
  }

  @override
  String nBodyResponseAccepted(String actor, String task) {
    return '$actor participe à « $task ».';
  }

  @override
  String nBodyResponseDeclined(String actor, String task) {
    return '$actor ne participe pas à « $task ».';
  }

  @override
  String nBodyMemberJoined(String actor, String tribe) {
    return '$actor a rejoint $tribe.';
  }

  @override
  String nBodyMemberLeft(String actor, String tribe) {
    return '$actor ne fait plus partie de $tribe.';
  }

  @override
  String nBodyKicked(String actor, String tribe) {
    return '$actor vous a retiré(e) de $tribe.';
  }

  @override
  String nBodyRenamed(String actor, String oldName, String newName) {
    return '$actor a renommé « $oldName » en « $newName ».';
  }

  @override
  String nBodyDissolved(String actor, String tribe) {
    return '$actor a dissous $tribe.';
  }

  @override
  String nBodyRoleVice(String tribe) {
    return 'Vous êtes maintenant co-chef de $tribe.';
  }

  @override
  String nBodyRoleViceRemoved(String tribe) {
    return 'Vous n\'êtes plus co-chef de $tribe.';
  }

  @override
  String nBodyRoleLeader(String tribe) {
    return 'Vous êtes maintenant chef de $tribe.';
  }

  @override
  String nBodyPersonalAdded(String task, String time) {
    return 'Vous avez ajouté « $task » à $time.';
  }

  @override
  String itemsTodaySubtitle(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
    );
    return '$_temp0 • Aujourd\'hui $date';
  }

  @override
  String get emptyDayHint =>
      'Rien de prévu — touchez une heure pour ajouter une activité';

  @override
  String get noGroupActivitiesDay => 'Aucune activité de tribu ce jour-là';

  @override
  String get newActivity => 'Nouvelle activité';

  @override
  String get editActivity => 'Modifier l\'activité';

  @override
  String get activityNameHint => 'Nom de l\'activité...';

  @override
  String get errorNameRequired => 'Donnez un nom à cette activité';

  @override
  String get errorNameTooShort => 'Le nom doit comporter au moins 2 caractères';

  @override
  String get date => 'Date';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get color => 'Couleur';

  @override
  String get colorLongPressHint => '(appui long pour changer)';

  @override
  String get pickNewColor => 'Choisir une couleur';

  @override
  String get reminder => 'Rappel';

  @override
  String get remindOnTime => 'À l\'heure';

  @override
  String remindBefore(int minutes) {
    return '$minutes min avant';
  }

  @override
  String get note => 'Notes';

  @override
  String get noteHint => 'Ajouter une note...';

  @override
  String get duplicateToOtherDays => 'Copier vers d\'autres jours';

  @override
  String get duplicateNone => 'Aucun jour choisi';

  @override
  String get duplicateTitle => 'Choisir les jours';

  @override
  String get duplicateDescription =>
      'À partir d\'aujourd\'hui seulement. Les jours déjà occupés à cette heure sont bloqués.';

  @override
  String get conflictingDay => 'Conflit horaire';

  @override
  String selectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Choisir $count jours',
      one: 'Choisir 1 jour',
    );
    return '$_temp0';
  }

  @override
  String savedWithCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enregistré et copié sur $count jours',
      one: 'Enregistré et copié sur 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get errorEndBeforeStart =>
      'L\'heure de fin doit suivre l\'heure de début';

  @override
  String get errorMinDuration => 'Une activité doit durer au moins 5 minutes';

  @override
  String get errorPastDate => 'Impossible de planifier sur un jour passé';

  @override
  String get errorOverlap => 'Ce créneau chevauche une autre activité';

  @override
  String get errorColorDuplicate => 'Cette couleur est déjà dans votre palette';

  @override
  String get deleteActivityTitle => 'Supprimer l\'activité ?';

  @override
  String deleteActivityMessage(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get activityDeleted => 'Activité supprimée';

  @override
  String get yourTemplates => 'Vos modèles';

  @override
  String get noTemplatesTitle => 'Aucun modèle pour le moment';

  @override
  String get noTemplatesMessage =>
      'Créez une semaine type pour remplir votre planning, ou importez celle d’un ami.';

  @override
  String get createTemplate => 'Créer un modèle';

  @override
  String get createTemplateHint => 'Partir d’une semaine vide';

  @override
  String get importTemplate => 'Importer via un lien';

  @override
  String get importTemplateHint => 'Saisissez un code partagé par un ami';

  @override
  String get importAction => 'Importer';

  @override
  String get templateImported => 'Modèle ajouté !';

  @override
  String get errorLinkEmpty => 'Collez un lien';

  @override
  String get errorTemplateNotFound => 'Aucun modèle trouvé pour ce code';

  @override
  String get errorTemplateDuplicate => 'Vous avez déjà ce modèle';

  @override
  String errorTemplateLimit(int max) {
    return 'Bibliothèque pleine ($max modèles max)';
  }

  @override
  String get errorTemplateNameEmpty => 'Donnez un nom au modèle';

  @override
  String get templateNameHint => 'Nom du modèle...';

  @override
  String activitiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
    );
    return '$_temp0';
  }

  @override
  String get apply => 'Appliquer';

  @override
  String get applyTemplate => 'Appliquer le modèle';

  @override
  String get applyTemplateDescription =>
      'Choisissez les jours à copier dans votre planning.';

  @override
  String get applyTemplateNote =>
      'Commence au prochain jour correspondant (aujourd’hui ou après).';

  @override
  String get repeatWeeks => 'Semaines';

  @override
  String get applyNow => 'Appliquer';

  @override
  String get errorPickAtLeastOneDay => 'Choisissez au moins un jour';

  @override
  String get conflictTitle => 'Conflit de planning';

  @override
  String conflictMessage(int count, String dates) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités se chevauchent',
      one: '1 activité se chevauche',
    );
    return '$_temp0 les : $dates.\n\nElles seront remplacées.';
  }

  @override
  String get replaceAndAdd => 'Remplacer et ajouter';

  @override
  String templateApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités ajoutées !',
      one: '1 activité ajoutée !',
    );
    return '$_temp0';
  }

  @override
  String templateAppliedReplaced(int added, int replaced) {
    return '$added activités ajoutées ($replaced remplacées)';
  }

  @override
  String get deleteTemplateTitle => 'Supprimer le modèle ?';

  @override
  String deleteTemplateMessage(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get templateDeleted => 'Modèle supprimé';

  @override
  String get shareTemplate => 'Partager le modèle';

  @override
  String get shareTemplateDescription =>
      'Envoyez ce code à un ami, il pourra le saisir dans Importer un modèle pour le copier.';

  @override
  String get addActivity => 'Ajouter une activité';

  @override
  String get dayOfWeek => 'Jour de la semaine';

  @override
  String get yourTribes => 'Vos tribus';

  @override
  String get noTribesTitle => 'Vous n\'êtes dans aucune tribu';

  @override
  String get noTribesMessage =>
      'Créez une tribu pour trouver du temps libre commun, ou rejoignez-en une via un lien.';

  @override
  String get createTribe => 'Créer une tribu';

  @override
  String get createTribeHint => 'Vous en serez le chef';

  @override
  String get joinTribe => 'Rejoindre une tribu';

  @override
  String get joinTribeHint => 'Utilisez un lien d\'invitation';

  @override
  String get joinTribeDescription => 'Collez le lien d\'invitation reçu.';

  @override
  String get join => 'Rejoindre';

  @override
  String get openTribe => 'Ouvrir la tribu';

  @override
  String get tribeNameHint => 'ex. Équipe projet, Club de badminton...';

  @override
  String get tribeCreated =>
      'Tribu créée ! Invitez vos amis depuis la liste des membres.';

  @override
  String joinedTribe(String name) {
    return 'Vous avez rejoint $name !';
  }

  @override
  String get infoAlreadyMember => 'Vous êtes déjà dans cette tribu';

  @override
  String infoAlreadyMemberOf(String name) {
    return 'Vous êtes déjà membre de « $name », inutile de rejoindre à nouveau.';
  }

  @override
  String get renameTribe => 'Renommer la tribu';

  @override
  String get tribeRenamed => 'Tribu renommée';

  @override
  String get tribeColor => 'Couleur de la tribu';

  @override
  String get tribeColorUpdated => 'Couleur mise à jour';

  @override
  String get inviteShareLink => 'Inviter / partager le lien';

  @override
  String inviteTo(String name) {
    return 'Inviter dans $name';
  }

  @override
  String inviteDescription(int max, int current) {
    return 'Toute personne avec ce lien peut rejoindre ($max membres max, actuellement $current).';
  }

  @override
  String get inviteMembers => 'Inviter des membres';

  @override
  String get dissolveTribe => 'Dissoudre la tribu';

  @override
  String get dissolveTribeTitle => 'Dissoudre la tribu ?';

  @override
  String dissolveTribeMessage(String name) {
    return 'Dissoudre $name ? Toutes ses activités seront supprimées et les membres prévenus.';
  }

  @override
  String get dissolve => 'Dissoudre';

  @override
  String tribeDissolved(String name) {
    return '$name a été dissoute';
  }

  @override
  String membersCount(int count, int max) {
    return '$count/$max membres';
  }

  @override
  String get noUpcomingActivity => 'Aucune activité à venir';

  @override
  String pendingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités attendent votre réponse',
      one: '1 activité attend votre réponse',
    );
    return '$_temp0';
  }

  @override
  String get roleLeader => 'Chef';

  @override
  String get roleVice => 'Co-chef';

  @override
  String get roleMember => 'Membre';

  @override
  String get members => 'Membres';

  @override
  String tribeSubtitle(int count, String offset) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0 · $offset';
  }

  @override
  String get createGroupActivity => 'Créer une activité';

  @override
  String groupActivitiesToday(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
    );
    return '$_temp0 • Aujourd\'hui $date';
  }

  @override
  String get legendFree => 'Libre';

  @override
  String get legendHalf => 'Mi-occupé';

  @override
  String get legendBusy => 'Occupé';

  @override
  String get commonFreeTime => 'Libre ensemble';

  @override
  String get membersSchedule => 'Disponibilités';

  @override
  String get groupActivities => 'Activités de la tribu';

  @override
  String get noCommonFreeTime =>
      'Aucun créneau commun ce jour-là. Essayez un jour vert !';

  @override
  String busyCount(int busy, int total) {
    return '$busy/$total occupés';
  }

  @override
  String get everyoneIsFree => 'Tout le monde est libre';

  @override
  String get freeSlotTapToCreate => 'Tous libres · touchez pour créer';

  @override
  String everyoneFree(int total) {
    return 'Les $total membres sont libres 🎉';
  }

  @override
  String someBusy(int busy, int total) {
    return '$busy/$total membres occupés. Les détails restent privés.';
  }

  @override
  String get theirTime => 'Leur heure';

  @override
  String get createInThisSlot => 'Créer une activité ici';

  @override
  String get waitingForYou => 'À vous';

  @override
  String get leaveTribe => 'Quitter la tribu';

  @override
  String get leaveTribeTitle => 'Quitter la tribu ?';

  @override
  String leaveTribeMessage(String tribe) {
    return 'Quitter $tribe ? Les membres seront prévenus.';
  }

  @override
  String leaveAloneMessage(String tribe) {
    return 'Vous êtes seul(e) — partir dissoudra $tribe.';
  }

  @override
  String leaveAsLeaderMessage(String name, String tribe) {
    return '$name deviendra chef. Quitter $tribe ?';
  }

  @override
  String leftTribe(String tribe) {
    return 'Vous avez quitté $tribe';
  }

  @override
  String get chooseNewLeader => 'Choisir un nouveau chef';

  @override
  String get chooseNewLeaderMessage =>
      'Une tribu a besoin d\'un chef — désignez quelqu\'un avant de partir.';

  @override
  String get appointVice => 'Nommer co-chef';

  @override
  String get appointLeader => 'Nommer chef';

  @override
  String get dismissVice => 'Retirer co-chef';

  @override
  String get kick => 'Retirer de la tribu';

  @override
  String get appoint => 'Nommer';

  @override
  String get dismiss => 'Retirer';

  @override
  String appointedVice(String name) {
    return '$name est maintenant co-chef.';
  }

  @override
  String appointedLeader(String name) {
    return '$name est maintenant chef.';
  }

  @override
  String dismissedVice(String name) {
    return '$name n\'est plus co-chef.';
  }

  @override
  String get dismissViceTitle => 'Retirer le co-chef ?';

  @override
  String dismissViceMessage(String name) {
    return '$name redeviendra membre.';
  }

  @override
  String get transferLeaderTitle => 'Transférer le rôle de chef ?';

  @override
  String transferLeaderToVice(String name) {
    return '$name deviendra chef. Vous deviendrez co-chef.';
  }

  @override
  String transferLeaderToMember(String name) {
    return '$name deviendra chef. Vous deviendrez membre (déjà 3 co-chefs).';
  }

  @override
  String get kickTitle => 'Retirer ce membre ?';

  @override
  String kickMessage(String name, String tribe) {
    return 'Retirer $name de $tribe ?';
  }

  @override
  String kicked(String name) {
    return '$name a été retiré(e)';
  }

  @override
  String get newGroupActivity => 'Nouvelle activité de tribu';

  @override
  String get activityDetails => 'Détails de l\'activité';

  @override
  String timezoneNote(String offset) {
    return 'Heures dans votre fuseau ($offset). Chaque membre voit son heure locale.';
  }

  @override
  String membersFreeCount(int free, int total) {
    return '$free/$total membres libres';
  }

  @override
  String get areBusy => 'sont occupés';

  @override
  String get eachMembersTime => 'Heure de chacun';

  @override
  String get oneHourBefore => '1 heure avant';

  @override
  String get noteHintGroup => 'Ajouter une note pour tous...';

  @override
  String get noNote => 'Aucune note';

  @override
  String get areYouJoining => 'Vous participez ?';

  @override
  String get attendanceAccepted => 'Je participe';

  @override
  String get attendanceDeclined => 'Je ne participe pas';

  @override
  String get attendancePending => 'Sans réponse';

  @override
  String get nobodyYet => 'Personne pour le moment';

  @override
  String get saveChangesTitle => 'Enregistrer les modifications ?';

  @override
  String get createActivityTitle => 'Créer l\'activité ?';

  @override
  String warnOverlapsWith(String list) {
    return 'Chevauche : $list.';
  }

  @override
  String warnMembersBusy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres sont occupés à ce moment.',
      one: '1 membre est occupé à ce moment.',
    );
    return '$_temp0';
  }

  @override
  String get warnReconfirm =>
      'Changer l\'horaire demandera à chacun de reconfirmer.';

  @override
  String get everyoneWillBeNotified => 'Tous les membres seront prévenus.';

  @override
  String savedAndNotified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enregistré et envoyé à $count membres',
      one: 'Enregistré et envoyé à 1 membre',
    );
    return '$_temp0';
  }

  @override
  String get errorSlotInPast => 'Ce créneau est déjà passé';

  @override
  String get activityCancelled => 'Cette activité a été annulée.';

  @override
  String get activityEnded => 'Cette activité est terminée.';

  @override
  String get respondedAccepted =>
      'Vous participez ! Elle apparaît dans votre planning.';

  @override
  String get respondedDeclined => 'Bien noté. Les chefs ont été prévenus.';

  @override
  String get errorTribeNameEmpty => 'Saisissez un nom de tribu';

  @override
  String errorTribeNameTooLong(int max) {
    return 'Nom trop long ($max caractères max)';
  }

  @override
  String errorTribeLimit(int max) {
    return 'Vous êtes déjà dans $max tribus. Quittez-en une pour en créer ou rejoindre une autre.';
  }

  @override
  String get errorInvalidLink => 'Ce lien semble invalide, vérifiez-le';

  @override
  String get errorTribeNotFound =>
      'Aucune tribu trouvée pour ce lien. Elle a peut-être été dissoute ou le lien est erroné.';

  @override
  String errorTribeFull(int max) {
    return 'Cette tribu est complète ($max membres)';
  }

  @override
  String errorTribeFullNamed(String name, int max) {
    return '« $name » compte déjà $max membres.';
  }

  @override
  String errorViceLimit(int max) {
    return 'Déjà $max co-chefs';
  }

  @override
  String get errorNeedNewLeader => 'Désignez un nouveau chef avant de partir';

  @override
  String get errorNotAllowed => 'Vous n\'avez pas l\'autorisation';

  @override
  String get errorItemGone => 'Cet élément n\'existe plus';

  @override
  String get errorNameLength =>
      'Le nom doit contenir entre 2 et 100 caractères';

  @override
  String get errorPasswordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get errorEmailTaken => 'Cet e-mail est déjà utilisé';

  @override
  String get errorNameTaken => 'Ce nom est déjà pris';

  @override
  String get errorAccountBanned => 'Votre compte est bloqué';

  @override
  String get errorAccountDeleted => 'Ce compte a été supprimé';

  @override
  String get errorGoogleAccount =>
      'Ce compte utilise Google, choisissez Se connecter avec Google';

  @override
  String get errorGoogleFailed =>
      'La connexion Google a échoué, veuillez réessayer';

  @override
  String get errorGoogleUnsupported =>
      'La connexion Google n\'est pas disponible sur cet appareil';

  @override
  String get errorNetwork =>
      'Impossible de joindre le serveur, vérifiez votre connexion';

  @override
  String get errorServer => 'Une erreur s\'est produite, veuillez réessayer';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordMessage =>
      'Saisissez l\'e-mail de votre compte, nous vous enverrons un lien de réinitialisation.';

  @override
  String get forgotPasswordSent =>
      'Si l\'e-mail existe, un lien de réinitialisation a été envoyé';

  @override
  String get sendLabel => 'Envoyer';

  @override
  String get sessionEnded =>
      'Votre session a pris fin, le compte s\'est peut-être connecté sur un autre appareil';

  @override
  String get changeAvatar => 'Changer la photo de profil';

  @override
  String get pickFromGallery => 'Choisir dans la galerie';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get avatarUpdated => 'Photo de profil mise à jour';

  @override
  String get errorBlockEnded => 'Cette activité est déjà terminée';

  @override
  String get pullToRefresh => 'Tirez pour actualiser';

  @override
  String get importTemplateCodeHint =>
      'Saisissez le code de partage reçu, par exemple GYM4DAY';

  @override
  String get errorCodeEmpty => 'Veuillez saisir un code';

  @override
  String get codeCopied => 'Code copié !';

  @override
  String nTitleReminder(String task) {
    return 'Bientôt : $task';
  }

  @override
  String nBodyPersonalReminder(String task, String time) {
    return '« $task » commence à $time.';
  }

  @override
  String nBodyTribeReminder(String tribe, String time) {
    return 'Une activité de $tribe commence à $time.';
  }

  @override
  String get onbSkip => 'Passer';

  @override
  String get onbNext => 'Suivant';

  @override
  String get onbBack => 'Retour';

  @override
  String get onbWelcomeTitle => 'Bienvenue sur TimeTribe !';

  @override
  String get onbWelcomeBody =>
      'L\'endroit pour organiser votre temps et planifier avec tout votre groupe en quelques gestes.';

  @override
  String get onbPersonalTitle => 'Un agenda personnel bien rangé';

  @override
  String get onbPersonalBody =>
      'Découpez votre journée en blocs, colorez chaque tâche, réutilisez des modèles et recevez un rappel avant le début.';

  @override
  String get onbTribeTitle => 'Planifier en groupe, simplement';

  @override
  String get onbTribeBody =>
      'Créez une Tribe, invitez vos amis avec un code et voyez aussitôt quand tout le monde est libre, même sur des fuseaux différents.';

  @override
  String get onbNotiTitle => 'Ne ratez rien';

  @override
  String get onbNotiBody =>
      'Soyez averti quand votre Tribe ajoute une activité et répondez Participer / Décliner d\'un seul geste.';

  @override
  String get onbChoiceTitle => 'Connaissez-vous déjà TimeTribe ?';

  @override
  String get onbChoiceSubtitle => 'Choisissez une option pour bien démarrer.';

  @override
  String get onbChoiceExpert => 'Je sais déjà l\'utiliser';

  @override
  String get onbChoiceExpertDesc => 'Aller directement à l\'accueil.';

  @override
  String get onbChoiceNewbie => 'Je suis nouveau';

  @override
  String get onbChoiceNewbieDesc =>
      'Faites un tour rapide des fonctions principales (environ 1 minute).';

  @override
  String get tourMenuTitle => 'Menu des fonctions';

  @override
  String get tourMenuBody =>
      'Passez de l\'agenda personnel aux Tribes et aux modèles ici.';

  @override
  String get tourContentTitle => 'Votre agenda';

  @override
  String get tourContentBody =>
      'Vos blocs de la journée s\'affichent ici. Choisissez une autre date en haut, touchez un bloc pour le voir ou le modifier.';

  @override
  String get tourAddTitle => 'Bouton créer';

  @override
  String get tourAddBody =>
      'Ajoutez un bloc, créez ou rejoignez une Tribe, ou créez un modèle, selon la section ouverte.';

  @override
  String get tourNotiTitle => 'Notifications';

  @override
  String get tourNotiBody =>
      'Les rappels et invitations aux activités de vos Tribes arrivent ici. Répondez directement depuis la liste.';

  @override
  String get tourProfileTitle => 'Profil';

  @override
  String get tourProfileBody =>
      'Modifiez photo, nom et fuseau horaire. Un bon fuseau permet à votre Tribe de voir vos vraies disponibilités.';

  @override
  String get tourSettingsTitle => 'Paramètres';

  @override
  String get tourSettingsBody =>
      'Changez le thème clair/sombre, la langue et revoyez ce guide à tout moment.';

  @override
  String get tourDone => 'C\'est parti !';

  @override
  String get help => 'Aide';

  @override
  String get replayTour => 'Revoir le guide';

  @override
  String get replayTourSubtitle => 'Un aperçu rapide des fonctions principales';

  @override
  String get view => 'Voir';

  @override
  String get testPush => 'Envoyer une notification test';

  @override
  String get testPushSubtitle =>
      'Vérifier que ce téléphone reçoit les notifications';

  @override
  String get testPushSent =>
      'Envoyée, elle devrait apparaître dans quelques secondes';

  @override
  String get testPushNoToken =>
      'Ce téléphone n\'a pas encore de jeton. Autorisez les notifications pour TimeTribe puis rouvrez l\'app.';

  @override
  String emailPendingLabel(String email) {
    return 'En attente de confirmation : $email';
  }

  @override
  String emailVerifySent(String email) {
    return 'Un lien de confirmation a été envoyé à $email. Ouvrez-le pour terminer le changement d\'e-mail.';
  }

  @override
  String get emailPendingCancel => 'Annuler le changement d\'e-mail';

  @override
  String get emailPendingCancelled => 'Changement d\'e-mail annulé';

  @override
  String get emailPendingHint =>
      'L\'e-mail ne change qu\'après avoir ouvert le lien envoyé à la nouvelle adresse.';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle => 'Modifier le mot de passe de connexion';

  @override
  String get setPassword => 'Créer un mot de passe';

  @override
  String get setPasswordSubtitle =>
      'Compte Google : ajoutez un mot de passe pour vous connecter par e-mail';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get errorWrongCurrentPassword =>
      'Le mot de passe actuel est incorrect';

  @override
  String get errorSamePassword =>
      'Le nouveau mot de passe doit être différent de l\'actuel';

  @override
  String get changePasswordNote =>
      'Après le changement, tous les appareils sont déconnectés et vous devez vous reconnecter avec le nouveau mot de passe.';

  @override
  String changePasswordPendingEmail(String email) {
    return 'La demande en attente de changement d\'e-mail vers $email sera annulée. Vous pourrez la refaire après connexion.';
  }

  @override
  String get passwordChangedRelogin =>
      'Mot de passe modifié. Reconnectez-vous avec le nouveau mot de passe.';

  @override
  String errorEmailTypo(String email) {
    return 'Cet e-mail semble mal saisi. Vouliez-vous dire $email ?';
  }

  @override
  String get errorEmailDomainInvalid =>
      'Le domaine de cet e-mail ne reçoit pas de courrier, vérifiez-le';

  @override
  String get errorEmailUnavailable =>
      'Le serveur ne peut pas envoyer d\'e-mail pour l\'instant, réessayez plus tard';

  @override
  String useSuggestion(String email) {
    return 'Utiliser $email';
  }
}
