// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class FluentLocalizationsEs extends FluentLocalizations {
  FluentLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Argentina (`es_AR`).
class FluentLocalizationsEsAr extends FluentLocalizationsEs {
  FluentLocalizationsEsAr() : super('es_AR');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Bolivia (`es_BO`).
class FluentLocalizationsEsBo extends FluentLocalizationsEs {
  FluentLocalizationsEsBo() : super('es_BO');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Chile (`es_CL`).
class FluentLocalizationsEsCl extends FluentLocalizationsEs {
  FluentLocalizationsEsCl() : super('es_CL');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Colombia (`es_CO`).
class FluentLocalizationsEsCo extends FluentLocalizationsEs {
  FluentLocalizationsEsCo() : super('es_CO');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Costa Rica (`es_CR`).
class FluentLocalizationsEsCr extends FluentLocalizationsEs {
  FluentLocalizationsEsCr() : super('es_CR');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in the Dominican Republic (`es_DO`).
class FluentLocalizationsEsDo extends FluentLocalizationsEs {
  FluentLocalizationsEsDo() : super('es_DO');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Ecuador (`es_EC`).
class FluentLocalizationsEsEc extends FluentLocalizationsEs {
  FluentLocalizationsEsEc() : super('es_EC');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class FluentLocalizationsEsEs extends FluentLocalizationsEs {
  FluentLocalizationsEsEs() : super('es_ES');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Guatemala (`es_GT`).
class FluentLocalizationsEsGt extends FluentLocalizationsEs {
  FluentLocalizationsEsGt() : super('es_GT');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Mexico (`es_MX`).
class FluentLocalizationsEsMx extends FluentLocalizationsEs {
  FluentLocalizationsEsMx() : super('es_MX');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Panama (`es_PA`).
class FluentLocalizationsEsPa extends FluentLocalizationsEs {
  FluentLocalizationsEsPa() : super('es_PA');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Peru (`es_PE`).
class FluentLocalizationsEsPe extends FluentLocalizationsEs {
  FluentLocalizationsEsPe() : super('es_PE');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Paraguay (`es_PY`).
class FluentLocalizationsEsPy extends FluentLocalizationsEs {
  FluentLocalizationsEsPy() : super('es_PY');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in the United States (`es_US`).
class FluentLocalizationsEsUs extends FluentLocalizationsEs {
  FluentLocalizationsEsUs() : super('es_US');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Uruguay (`es_UY`).
class FluentLocalizationsEsUy extends FluentLocalizationsEs {
  FluentLocalizationsEsUy() : super('es_UY');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}

/// The translations for Spanish Castilian, as used in Venezuela (`es_VE`).
class FluentLocalizationsEsVe extends FluentLocalizationsEs {
  FluentLocalizationsEsVe() : super('es_VE');

  @override
  String get close => 'Cerrar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get clear => 'Borrar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get more => 'Más';

  @override
  String get overflowMore => 'más';

  @override
  String get selectAllRows => 'Seleccionar todas las filas';

  @override
  String get selectRow => 'Seleccionar fila';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado de forma ascendente';

  @override
  String get sortedDescending => 'Ordenado de forma descendente';

  @override
  String get previousSlide => 'Diapositiva anterior';

  @override
  String get nextSlide => 'Diapositiva siguiente';

  @override
  String get startSlideShow => 'Iniciar presentación automática';

  @override
  String get pauseSlideShow => 'Pausar presentación automática';

  @override
  String slideOf(int index, int count) {
    return 'Diapositiva $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Paso $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String get invalidDateFormat => 'Formato de fecha no válido.';

  @override
  String get dateOutOfRange => 'La fecha está fuera del intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get goToToday => 'Ir a hoy';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get previousYear => 'Año anterior';

  @override
  String get nextYear => 'Año siguiente';

  @override
  String get previousYearRange => 'Intervalo de años anterior';

  @override
  String get nextYearRange => 'Intervalo de años siguiente';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, cambiar año';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, cambiar mes';
  }

  @override
  String selectedDate(String date) {
    return 'Fecha seleccionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Fecha de hoy $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'El gráfico no tiene datos para mostrar';

  @override
  String get chartNoDataAvailable => 'No hay datos disponibles';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'El eje $axis muestra $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundario';

  @override
  String get chartAxisCategories => 'categorías';

  @override
  String get chartAxisTime => 'tiempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Línea';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de embudo con $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anillos con $count sectores';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor con $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor actual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'El valor actual es $value';
  }

  @override
  String gaugeMinValue(String value) {
    return 'Valor mínimo: $value';
  }

  @override
  String gaugeMaxValue(String value) {
    return 'Valor máximo: $value';
  }

  @override
  String get gaugeUnknownSegment => 'Desconocido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt con $count puntos de datos. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor con $count puntos de datos. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar con $count series de datos.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico con la etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey con $nodes nodos y $links enlaces';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'Desde $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nodo $name con peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'enlace de $source a $target con peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticales con $count barras y 1 línea. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count series de barras agrupadas y $lines series de líneas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticales con $count barras apiladas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticales con $count barras apiladas y $lines líneas. ';
  }

  @override
  String get presenceAvailable => 'Disponible';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'No molestar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Sin conexión';

  @override
  String get presenceOutOfOffice => 'Fuera de la oficina';

  @override
  String get presenceUnknown => 'Desconocido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status fuera de la oficina';
  }
}
