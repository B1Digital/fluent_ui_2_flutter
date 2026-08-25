// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class FluentLocalizationsFr extends FluentLocalizations {
  FluentLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get close => 'Fermer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get clear => 'Effacer';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Supprimer';

  @override
  String get more => 'Plus';

  @override
  String get overflowMore => 'autres';

  @override
  String get selectAllRows => 'Sélectionner toutes les lignes';

  @override
  String get selectRow => 'Sélectionner la ligne';

  @override
  String get sort => 'Trier';

  @override
  String get sortedAscending => 'Tri croissant';

  @override
  String get sortedDescending => 'Tri décroissant';

  @override
  String get previousSlide => 'Diapositive précédente';

  @override
  String get nextSlide => 'Diapositive suivante';

  @override
  String get startSlideShow => 'Démarrer le diaporama automatique';

  @override
  String get pauseSlideShow => 'Suspendre le diaporama automatique';

  @override
  String slideOf(int index, int count) {
    return 'Diapositive $index sur $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Étape $index sur $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value sur $max';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String get invalidDateFormat => 'Format de date non valide.';

  @override
  String get dateOutOfRange => 'La date est en dehors de la plage autorisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousYearRange => 'Plage d\'années précédente';

  @override
  String get nextYearRange => 'Plage d\'années suivante';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, changer d\'année';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, changer de mois';
  }

  @override
  String selectedDate(String date) {
    return 'Date sélectionnée $date';
  }

  @override
  String todaysDate(String date) {
    return 'Date du jour $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semaine $number';
  }

  @override
  String get chartNoData => 'Le graphique n\'a aucune donnée à afficher';

  @override
  String get chartNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get chartFallbackTitle => 'Graphique. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'axe $axis affiche $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondaire';

  @override
  String get chartAxisCategories => 'les catégories';

  @override
  String get chartAxisTime => 'le temps';

  @override
  String get chartAxisValues => 'les valeurs';

  @override
  String get chartLineLegendFallback => 'Courbe';

  @override
  String funnelChartDescription(int count) {
    return 'Graphique en entonnoir avec $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Graphique en anneau avec $count secteurs';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Graphique en jauge avec $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valeur actuelle : $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'La valeur actuelle est $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valeur minimale : $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valeur maximale : $value';
  }

  @override
  String get gaugeUnknownSegment => 'Inconnu';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramme de Gantt avec $count points de données. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carte thermique avec $count points de données. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Graphique polaire avec $count séries de données.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Graphique sparkline avec l\'étiquette $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramme de Sankey avec $nodes nœuds et $links liens';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nœud $name avec un poids de $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'lien de $source vers $target avec un poids de $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Graphique à barres verticales avec $count barres et 1 courbe. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count séries de barres groupées. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count séries de barres groupées et $lines séries de courbes. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres empilées. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count barres empilées et $lines courbes. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceBusy => 'Occupé';

  @override
  String get presenceDoNotDisturb => 'Ne pas déranger';

  @override
  String get presenceBlocked => 'Bloqué';

  @override
  String get presenceOffline => 'Hors connexion';

  @override
  String get presenceOutOfOffice => 'Absent du bureau';

  @override
  String get presenceUnknown => 'Inconnu';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, absent du bureau';
  }
}

/// The translations for French, as used in Belgium (`fr_BE`).
class FluentLocalizationsFrBe extends FluentLocalizationsFr {
  FluentLocalizationsFrBe() : super('fr_BE');

  @override
  String get close => 'Fermer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get clear => 'Effacer';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Supprimer';

  @override
  String get more => 'Plus';

  @override
  String get overflowMore => 'autres';

  @override
  String get selectAllRows => 'Sélectionner toutes les lignes';

  @override
  String get selectRow => 'Sélectionner la ligne';

  @override
  String get sort => 'Trier';

  @override
  String get sortedAscending => 'Tri croissant';

  @override
  String get sortedDescending => 'Tri décroissant';

  @override
  String get previousSlide => 'Diapositive précédente';

  @override
  String get nextSlide => 'Diapositive suivante';

  @override
  String get startSlideShow => 'Démarrer le diaporama automatique';

  @override
  String get pauseSlideShow => 'Suspendre le diaporama automatique';

  @override
  String slideOf(int index, int count) {
    return 'Diapositive $index sur $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Étape $index sur $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value sur $max';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String get invalidDateFormat => 'Format de date non valide.';

  @override
  String get dateOutOfRange => 'La date est en dehors de la plage autorisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousYearRange => 'Plage d\'années précédente';

  @override
  String get nextYearRange => 'Plage d\'années suivante';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, changer d\'année';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, changer de mois';
  }

  @override
  String selectedDate(String date) {
    return 'Date sélectionnée $date';
  }

  @override
  String todaysDate(String date) {
    return 'Date du jour $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semaine $number';
  }

  @override
  String get chartNoData => 'Le graphique n\'a aucune donnée à afficher';

  @override
  String get chartNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get chartFallbackTitle => 'Graphique. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'axe $axis affiche $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondaire';

  @override
  String get chartAxisCategories => 'les catégories';

  @override
  String get chartAxisTime => 'le temps';

  @override
  String get chartAxisValues => 'les valeurs';

  @override
  String get chartLineLegendFallback => 'Courbe';

  @override
  String funnelChartDescription(int count) {
    return 'Graphique en entonnoir avec $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Graphique en anneau avec $count secteurs';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Graphique en jauge avec $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valeur actuelle : $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'La valeur actuelle est $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valeur minimale : $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valeur maximale : $value';
  }

  @override
  String get gaugeUnknownSegment => 'Inconnu';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramme de Gantt avec $count points de données. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carte thermique avec $count points de données. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Graphique polaire avec $count séries de données.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Graphique sparkline avec l\'étiquette $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramme de Sankey avec $nodes nœuds et $links liens';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nœud $name avec un poids de $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'lien de $source vers $target avec un poids de $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Graphique à barres verticales avec $count barres et 1 courbe. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count séries de barres groupées. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count séries de barres groupées et $lines séries de courbes. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres empilées. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count barres empilées et $lines courbes. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceBusy => 'Occupé';

  @override
  String get presenceDoNotDisturb => 'Ne pas déranger';

  @override
  String get presenceBlocked => 'Bloqué';

  @override
  String get presenceOffline => 'Hors connexion';

  @override
  String get presenceOutOfOffice => 'Absent du bureau';

  @override
  String get presenceUnknown => 'Inconnu';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, absent du bureau';
  }
}

/// The translations for French, as used in Canada (`fr_CA`).
class FluentLocalizationsFrCa extends FluentLocalizationsFr {
  FluentLocalizationsFrCa() : super('fr_CA');

  @override
  String get close => 'Fermer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get clear => 'Effacer';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Supprimer';

  @override
  String get more => 'Plus';

  @override
  String get overflowMore => 'autres';

  @override
  String get selectAllRows => 'Sélectionner toutes les lignes';

  @override
  String get selectRow => 'Sélectionner la ligne';

  @override
  String get sort => 'Trier';

  @override
  String get sortedAscending => 'Tri croissant';

  @override
  String get sortedDescending => 'Tri décroissant';

  @override
  String get previousSlide => 'Diapositive précédente';

  @override
  String get nextSlide => 'Diapositive suivante';

  @override
  String get startSlideShow => 'Démarrer le diaporama automatique';

  @override
  String get pauseSlideShow => 'Suspendre le diaporama automatique';

  @override
  String slideOf(int index, int count) {
    return 'Diapositive $index sur $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Étape $index sur $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value sur $max';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String get invalidDateFormat => 'Format de date non valide.';

  @override
  String get dateOutOfRange => 'La date est en dehors de la plage autorisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousYearRange => 'Plage d\'années précédente';

  @override
  String get nextYearRange => 'Plage d\'années suivante';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, changer d\'année';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, changer de mois';
  }

  @override
  String selectedDate(String date) {
    return 'Date sélectionnée $date';
  }

  @override
  String todaysDate(String date) {
    return 'Date du jour $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semaine $number';
  }

  @override
  String get chartNoData => 'Le graphique n\'a aucune donnée à afficher';

  @override
  String get chartNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get chartFallbackTitle => 'Graphique. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'axe $axis affiche $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondaire';

  @override
  String get chartAxisCategories => 'les catégories';

  @override
  String get chartAxisTime => 'le temps';

  @override
  String get chartAxisValues => 'les valeurs';

  @override
  String get chartLineLegendFallback => 'Courbe';

  @override
  String funnelChartDescription(int count) {
    return 'Graphique en entonnoir avec $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Graphique en anneau avec $count secteurs';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Graphique en jauge avec $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valeur actuelle : $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'La valeur actuelle est $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valeur minimale : $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valeur maximale : $value';
  }

  @override
  String get gaugeUnknownSegment => 'Inconnu';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramme de Gantt avec $count points de données. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carte thermique avec $count points de données. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Graphique polaire avec $count séries de données.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Graphique sparkline avec l\'étiquette $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramme de Sankey avec $nodes nœuds et $links liens';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nœud $name avec un poids de $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'lien de $source vers $target avec un poids de $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Graphique à barres verticales avec $count barres et 1 courbe. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count séries de barres groupées. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count séries de barres groupées et $lines séries de courbes. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres empilées. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count barres empilées et $lines courbes. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceBusy => 'Occupé';

  @override
  String get presenceDoNotDisturb => 'Ne pas déranger';

  @override
  String get presenceBlocked => 'Bloqué';

  @override
  String get presenceOffline => 'Hors connexion';

  @override
  String get presenceOutOfOffice => 'Absent du bureau';

  @override
  String get presenceUnknown => 'Inconnu';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, absent du bureau';
  }
}

/// The translations for French, as used in Switzerland (`fr_CH`).
class FluentLocalizationsFrCh extends FluentLocalizationsFr {
  FluentLocalizationsFrCh() : super('fr_CH');

  @override
  String get close => 'Fermer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get clear => 'Effacer';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Supprimer';

  @override
  String get more => 'Plus';

  @override
  String get overflowMore => 'autres';

  @override
  String get selectAllRows => 'Sélectionner toutes les lignes';

  @override
  String get selectRow => 'Sélectionner la ligne';

  @override
  String get sort => 'Trier';

  @override
  String get sortedAscending => 'Tri croissant';

  @override
  String get sortedDescending => 'Tri décroissant';

  @override
  String get previousSlide => 'Diapositive précédente';

  @override
  String get nextSlide => 'Diapositive suivante';

  @override
  String get startSlideShow => 'Démarrer le diaporama automatique';

  @override
  String get pauseSlideShow => 'Suspendre le diaporama automatique';

  @override
  String slideOf(int index, int count) {
    return 'Diapositive $index sur $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Étape $index sur $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value sur $max';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String get invalidDateFormat => 'Format de date non valide.';

  @override
  String get dateOutOfRange => 'La date est en dehors de la plage autorisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousYearRange => 'Plage d\'années précédente';

  @override
  String get nextYearRange => 'Plage d\'années suivante';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, changer d\'année';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, changer de mois';
  }

  @override
  String selectedDate(String date) {
    return 'Date sélectionnée $date';
  }

  @override
  String todaysDate(String date) {
    return 'Date du jour $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semaine $number';
  }

  @override
  String get chartNoData => 'Le graphique n\'a aucune donnée à afficher';

  @override
  String get chartNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get chartFallbackTitle => 'Graphique. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'axe $axis affiche $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondaire';

  @override
  String get chartAxisCategories => 'les catégories';

  @override
  String get chartAxisTime => 'le temps';

  @override
  String get chartAxisValues => 'les valeurs';

  @override
  String get chartLineLegendFallback => 'Courbe';

  @override
  String funnelChartDescription(int count) {
    return 'Graphique en entonnoir avec $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Graphique en anneau avec $count secteurs';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Graphique en jauge avec $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valeur actuelle : $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'La valeur actuelle est $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valeur minimale : $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valeur maximale : $value';
  }

  @override
  String get gaugeUnknownSegment => 'Inconnu';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramme de Gantt avec $count points de données. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carte thermique avec $count points de données. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Graphique polaire avec $count séries de données.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Graphique sparkline avec l\'étiquette $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramme de Sankey avec $nodes nœuds et $links liens';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nœud $name avec un poids de $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'lien de $source vers $target avec un poids de $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Graphique à barres verticales avec $count barres et 1 courbe. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count séries de barres groupées. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count séries de barres groupées et $lines séries de courbes. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres empilées. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count barres empilées et $lines courbes. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceBusy => 'Occupé';

  @override
  String get presenceDoNotDisturb => 'Ne pas déranger';

  @override
  String get presenceBlocked => 'Bloqué';

  @override
  String get presenceOffline => 'Hors connexion';

  @override
  String get presenceOutOfOffice => 'Absent du bureau';

  @override
  String get presenceUnknown => 'Inconnu';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, absent du bureau';
  }
}

/// The translations for French, as used in France (`fr_FR`).
class FluentLocalizationsFrFr extends FluentLocalizationsFr {
  FluentLocalizationsFrFr() : super('fr_FR');

  @override
  String get close => 'Fermer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get clear => 'Effacer';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Supprimer';

  @override
  String get more => 'Plus';

  @override
  String get overflowMore => 'autres';

  @override
  String get selectAllRows => 'Sélectionner toutes les lignes';

  @override
  String get selectRow => 'Sélectionner la ligne';

  @override
  String get sort => 'Trier';

  @override
  String get sortedAscending => 'Tri croissant';

  @override
  String get sortedDescending => 'Tri décroissant';

  @override
  String get previousSlide => 'Diapositive précédente';

  @override
  String get nextSlide => 'Diapositive suivante';

  @override
  String get startSlideShow => 'Démarrer le diaporama automatique';

  @override
  String get pauseSlideShow => 'Suspendre le diaporama automatique';

  @override
  String slideOf(int index, int count) {
    return 'Diapositive $index sur $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Étape $index sur $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value sur $max';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String get invalidDateFormat => 'Format de date non valide.';

  @override
  String get dateOutOfRange => 'La date est en dehors de la plage autorisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousYearRange => 'Plage d\'années précédente';

  @override
  String get nextYearRange => 'Plage d\'années suivante';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, changer d\'année';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, changer de mois';
  }

  @override
  String selectedDate(String date) {
    return 'Date sélectionnée $date';
  }

  @override
  String todaysDate(String date) {
    return 'Date du jour $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semaine $number';
  }

  @override
  String get chartNoData => 'Le graphique n\'a aucune donnée à afficher';

  @override
  String get chartNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get chartFallbackTitle => 'Graphique. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'axe $axis affiche $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondaire';

  @override
  String get chartAxisCategories => 'les catégories';

  @override
  String get chartAxisTime => 'le temps';

  @override
  String get chartAxisValues => 'les valeurs';

  @override
  String get chartLineLegendFallback => 'Courbe';

  @override
  String funnelChartDescription(int count) {
    return 'Graphique en entonnoir avec $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Graphique en anneau avec $count secteurs';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Graphique en jauge avec $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valeur actuelle : $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'La valeur actuelle est $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valeur minimale : $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valeur maximale : $value';
  }

  @override
  String get gaugeUnknownSegment => 'Inconnu';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramme de Gantt avec $count points de données. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carte thermique avec $count points de données. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Graphique polaire avec $count séries de données.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Graphique sparkline avec l\'étiquette $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramme de Sankey avec $nodes nœuds et $links liens';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nœud $name avec un poids de $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'lien de $source vers $target avec un poids de $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Graphique à barres verticales avec $count barres et 1 courbe. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count séries de barres groupées. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count séries de barres groupées et $lines séries de courbes. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres empilées. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count barres empilées et $lines courbes. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceBusy => 'Occupé';

  @override
  String get presenceDoNotDisturb => 'Ne pas déranger';

  @override
  String get presenceBlocked => 'Bloqué';

  @override
  String get presenceOffline => 'Hors connexion';

  @override
  String get presenceOutOfOffice => 'Absent du bureau';

  @override
  String get presenceUnknown => 'Inconnu';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, absent du bureau';
  }
}

/// The translations for French, as used in Luxembourg (`fr_LU`).
class FluentLocalizationsFrLu extends FluentLocalizationsFr {
  FluentLocalizationsFrLu() : super('fr_LU');

  @override
  String get close => 'Fermer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get clear => 'Effacer';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Supprimer';

  @override
  String get more => 'Plus';

  @override
  String get overflowMore => 'autres';

  @override
  String get selectAllRows => 'Sélectionner toutes les lignes';

  @override
  String get selectRow => 'Sélectionner la ligne';

  @override
  String get sort => 'Trier';

  @override
  String get sortedAscending => 'Tri croissant';

  @override
  String get sortedDescending => 'Tri décroissant';

  @override
  String get previousSlide => 'Diapositive précédente';

  @override
  String get nextSlide => 'Diapositive suivante';

  @override
  String get startSlideShow => 'Démarrer le diaporama automatique';

  @override
  String get pauseSlideShow => 'Suspendre le diaporama automatique';

  @override
  String slideOf(int index, int count) {
    return 'Diapositive $index sur $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Étape $index sur $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value sur $max';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String get invalidDateFormat => 'Format de date non valide.';

  @override
  String get dateOutOfRange => 'La date est en dehors de la plage autorisée.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get goToToday => 'Aller à aujourd\'hui';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousYearRange => 'Plage d\'années précédente';

  @override
  String get nextYearRange => 'Plage d\'années suivante';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, changer d\'année';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, changer de mois';
  }

  @override
  String selectedDate(String date) {
    return 'Date sélectionnée $date';
  }

  @override
  String todaysDate(String date) {
    return 'Date du jour $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semaine $number';
  }

  @override
  String get chartNoData => 'Le graphique n\'a aucune donnée à afficher';

  @override
  String get chartNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get chartFallbackTitle => 'Graphique. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'L\'axe $axis affiche $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secondaire';

  @override
  String get chartAxisCategories => 'les catégories';

  @override
  String get chartAxisTime => 'le temps';

  @override
  String get chartAxisValues => 'les valeurs';

  @override
  String get chartLineLegendFallback => 'Courbe';

  @override
  String funnelChartDescription(int count) {
    return 'Graphique en entonnoir avec $count segments';
  }

  @override
  String donutChartDescription(int count) {
    return 'Graphique en anneau avec $count secteurs';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Graphique en jauge avec $count segments. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valeur actuelle : $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'La valeur actuelle est $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valeur minimale : $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valeur maximale : $value';
  }

  @override
  String get gaugeUnknownSegment => 'Inconnu';

  @override
  String ganttChartDescription(int count) {
    return 'Diagramme de Gantt avec $count points de données. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Carte thermique avec $count points de données. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Graphique polaire avec $count séries de données.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Graphique sparkline avec l\'étiquette $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Diagramme de Sankey avec $nodes nœuds et $links liens';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nœud $name avec un poids de $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'lien de $source vers $target avec un poids de $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Graphique à barres verticales avec $count barres et 1 courbe. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count séries de barres groupées. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count séries de barres groupées et $lines séries de courbes. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Graphique à barres verticales avec $count barres empilées. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Graphique à barres verticales avec $count barres empilées et $lines courbes. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceBusy => 'Occupé';

  @override
  String get presenceDoNotDisturb => 'Ne pas déranger';

  @override
  String get presenceBlocked => 'Bloqué';

  @override
  String get presenceOffline => 'Hors connexion';

  @override
  String get presenceOutOfOffice => 'Absent du bureau';

  @override
  String get presenceUnknown => 'Inconnu';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, absent du bureau';
  }
}
