// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fluent_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class FluentLocalizationsPt extends FluentLocalizations {
  FluentLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get close => 'Fechar';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get clear => 'Limpar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Remover';

  @override
  String get more => 'Mais';

  @override
  String get overflowMore => 'mais';

  @override
  String get selectAllRows => 'Selecionar todas as linhas';

  @override
  String get selectRow => 'Selecionar linha';

  @override
  String get sort => 'Classificar';

  @override
  String get sortedAscending => 'Classificado em ordem crescente';

  @override
  String get sortedDescending => 'Classificado em ordem decrescente';

  @override
  String get previousSlide => 'Slide anterior';

  @override
  String get nextSlide => 'Próximo slide';

  @override
  String get startSlideShow => 'Iniciar apresentação automática de slides';

  @override
  String get pauseSlideShow => 'Pausar apresentação automática de slides';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Etapa $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendário';

  @override
  String get invalidDateFormat => 'Formato de data inválido.';

  @override
  String get dateOutOfRange => 'A data está fora do intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo é obrigatório.';

  @override
  String get goToToday => 'Ir para hoje';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Próximo mês';

  @override
  String get previousYear => 'Ano anterior';

  @override
  String get nextYear => 'Próximo ano';

  @override
  String get previousYearRange => 'Intervalo de anos anterior';

  @override
  String get nextYearRange => 'Próximo intervalo de anos';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, alterar ano';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, alterar mês';
  }

  @override
  String selectedDate(String date) {
    return 'Data selecionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de hoje $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'O gráfico não tem dados para exibir';

  @override
  String get chartNoDataAvailable => 'Nenhum dado disponível';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'O eixo $axis exibe $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundário';

  @override
  String get chartAxisCategories => 'categorias';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Linha';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de funil com $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de rosca com $count fatias';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor com $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor atual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'O valor atual é $value';
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
  String get gaugeUnknownSegment => 'Desconhecido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt com $count pontos de dados. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor com $count pontos de dados. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar com $count séries de dados.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico com o rótulo $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey com $nodes nós e $links ligações';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nó $name com peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ligação de $source para $target com peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticais com $count barras e 1 linha. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas e $lines séries de linhas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras empilhadas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count barras empilhadas e $lines linhas. ';
  }

  @override
  String get presenceAvailable => 'Disponível';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'Não incomodar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Fora do escritório';

  @override
  String get presenceUnknown => 'Desconhecido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, fora do escritório';
  }
}

/// The translations for Portuguese, as used in Angola (`pt_AO`).
class FluentLocalizationsPtAo extends FluentLocalizationsPt {
  FluentLocalizationsPtAo() : super('pt_AO');

  @override
  String get close => 'Fechar';

  @override
  String get dismiss => 'Ignorar';

  @override
  String get clear => 'Limpar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Remover';

  @override
  String get more => 'Mais';

  @override
  String get overflowMore => 'mais';

  @override
  String get selectAllRows => 'Selecionar todas as linhas';

  @override
  String get selectRow => 'Selecionar linha';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado por ordem ascendente';

  @override
  String get sortedDescending => 'Ordenado por ordem descendente';

  @override
  String get previousSlide => 'Diapositivo anterior';

  @override
  String get nextSlide => 'Diapositivo seguinte';

  @override
  String get startSlideShow =>
      'Iniciar apresentação automática de diapositivos';

  @override
  String get pauseSlideShow =>
      'Colocar em pausa a apresentação automática de diapositivos';

  @override
  String slideOf(int index, int count) {
    return 'Diapositivo $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Passo $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendário';

  @override
  String get invalidDateFormat => 'Formato de data inválido.';

  @override
  String get dateOutOfRange => 'A data está fora do intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo é obrigatório.';

  @override
  String get goToToday => 'Ir para hoje';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Mês seguinte';

  @override
  String get previousYear => 'Ano anterior';

  @override
  String get nextYear => 'Ano seguinte';

  @override
  String get previousYearRange => 'Intervalo de anos anterior';

  @override
  String get nextYearRange => 'Intervalo de anos seguinte';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, alterar ano';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, alterar mês';
  }

  @override
  String selectedDate(String date) {
    return 'Data selecionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de hoje $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'O gráfico não tem dados para apresentar';

  @override
  String get chartNoDataAvailable => 'Não existem dados disponíveis';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'O eixo $axis apresenta $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundário';

  @override
  String get chartAxisCategories => 'categorias';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Linha';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de funil com $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anel com $count fatias';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor com $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor atual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'O valor atual é $value';
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
  String get gaugeUnknownSegment => 'Desconhecido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt com $count pontos de dados. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor com $count pontos de dados. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar com $count séries de dados.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline com a etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey com $nodes nós e $links ligações';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nó $name com peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ligação de $source para $target com peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticais com $count barras e 1 linha. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas e $lines séries de linhas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras empilhadas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count barras empilhadas e $lines linhas. ';
  }

  @override
  String get presenceAvailable => 'Disponível';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'Não incomodar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Ausente do escritório';

  @override
  String get presenceUnknown => 'Desconhecido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, ausente do escritório';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class FluentLocalizationsPtBr extends FluentLocalizationsPt {
  FluentLocalizationsPtBr() : super('pt_BR');

  @override
  String get close => 'Fechar';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get clear => 'Limpar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Remover';

  @override
  String get more => 'Mais';

  @override
  String get overflowMore => 'mais';

  @override
  String get selectAllRows => 'Selecionar todas as linhas';

  @override
  String get selectRow => 'Selecionar linha';

  @override
  String get sort => 'Classificar';

  @override
  String get sortedAscending => 'Classificado em ordem crescente';

  @override
  String get sortedDescending => 'Classificado em ordem decrescente';

  @override
  String get previousSlide => 'Slide anterior';

  @override
  String get nextSlide => 'Próximo slide';

  @override
  String get startSlideShow => 'Iniciar apresentação automática de slides';

  @override
  String get pauseSlideShow => 'Pausar apresentação automática de slides';

  @override
  String slideOf(int index, int count) {
    return 'Slide $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Etapa $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendário';

  @override
  String get invalidDateFormat => 'Formato de data inválido.';

  @override
  String get dateOutOfRange => 'A data está fora do intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo é obrigatório.';

  @override
  String get goToToday => 'Ir para hoje';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Próximo mês';

  @override
  String get previousYear => 'Ano anterior';

  @override
  String get nextYear => 'Próximo ano';

  @override
  String get previousYearRange => 'Intervalo de anos anterior';

  @override
  String get nextYearRange => 'Próximo intervalo de anos';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, alterar ano';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, alterar mês';
  }

  @override
  String selectedDate(String date) {
    return 'Data selecionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de hoje $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'O gráfico não tem dados para exibir';

  @override
  String get chartNoDataAvailable => 'Nenhum dado disponível';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'O eixo $axis exibe $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundário';

  @override
  String get chartAxisCategories => 'categorias';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Linha';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de funil com $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de rosca com $count fatias';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor com $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor atual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'O valor atual é $value';
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
  String get gaugeUnknownSegment => 'Desconhecido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt com $count pontos de dados. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor com $count pontos de dados. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar com $count séries de dados.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Minigráfico com o rótulo $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey com $nodes nós e $links ligações';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nó $name com peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ligação de $source para $target com peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticais com $count barras e 1 linha. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas e $lines séries de linhas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras empilhadas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count barras empilhadas e $lines linhas. ';
  }

  @override
  String get presenceAvailable => 'Disponível';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'Não incomodar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Fora do escritório';

  @override
  String get presenceUnknown => 'Desconhecido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, fora do escritório';
  }
}

/// The translations for Portuguese, as used in Mozambique (`pt_MZ`).
class FluentLocalizationsPtMz extends FluentLocalizationsPt {
  FluentLocalizationsPtMz() : super('pt_MZ');

  @override
  String get close => 'Fechar';

  @override
  String get dismiss => 'Ignorar';

  @override
  String get clear => 'Limpar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Remover';

  @override
  String get more => 'Mais';

  @override
  String get overflowMore => 'mais';

  @override
  String get selectAllRows => 'Selecionar todas as linhas';

  @override
  String get selectRow => 'Selecionar linha';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado por ordem ascendente';

  @override
  String get sortedDescending => 'Ordenado por ordem descendente';

  @override
  String get previousSlide => 'Diapositivo anterior';

  @override
  String get nextSlide => 'Diapositivo seguinte';

  @override
  String get startSlideShow =>
      'Iniciar apresentação automática de diapositivos';

  @override
  String get pauseSlideShow =>
      'Colocar em pausa a apresentação automática de diapositivos';

  @override
  String slideOf(int index, int count) {
    return 'Diapositivo $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Passo $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendário';

  @override
  String get invalidDateFormat => 'Formato de data inválido.';

  @override
  String get dateOutOfRange => 'A data está fora do intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo é obrigatório.';

  @override
  String get goToToday => 'Ir para hoje';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Mês seguinte';

  @override
  String get previousYear => 'Ano anterior';

  @override
  String get nextYear => 'Ano seguinte';

  @override
  String get previousYearRange => 'Intervalo de anos anterior';

  @override
  String get nextYearRange => 'Intervalo de anos seguinte';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, alterar ano';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, alterar mês';
  }

  @override
  String selectedDate(String date) {
    return 'Data selecionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de hoje $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'O gráfico não tem dados para apresentar';

  @override
  String get chartNoDataAvailable => 'Não existem dados disponíveis';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'O eixo $axis apresenta $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundário';

  @override
  String get chartAxisCategories => 'categorias';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Linha';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de funil com $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anel com $count fatias';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor com $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor atual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'O valor atual é $value';
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
  String get gaugeUnknownSegment => 'Desconhecido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt com $count pontos de dados. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor com $count pontos de dados. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar com $count séries de dados.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline com a etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey com $nodes nós e $links ligações';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nó $name com peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ligação de $source para $target com peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticais com $count barras e 1 linha. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas e $lines séries de linhas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras empilhadas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count barras empilhadas e $lines linhas. ';
  }

  @override
  String get presenceAvailable => 'Disponível';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'Não incomodar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Ausente do escritório';

  @override
  String get presenceUnknown => 'Desconhecido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, ausente do escritório';
  }
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class FluentLocalizationsPtPt extends FluentLocalizationsPt {
  FluentLocalizationsPtPt() : super('pt_PT');

  @override
  String get close => 'Fechar';

  @override
  String get dismiss => 'Ignorar';

  @override
  String get clear => 'Limpar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Remover';

  @override
  String get more => 'Mais';

  @override
  String get overflowMore => 'mais';

  @override
  String get selectAllRows => 'Selecionar todas as linhas';

  @override
  String get selectRow => 'Selecionar linha';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortedAscending => 'Ordenado por ordem ascendente';

  @override
  String get sortedDescending => 'Ordenado por ordem descendente';

  @override
  String get previousSlide => 'Diapositivo anterior';

  @override
  String get nextSlide => 'Diapositivo seguinte';

  @override
  String get startSlideShow =>
      'Iniciar apresentação automática de diapositivos';

  @override
  String get pauseSlideShow =>
      'Colocar em pausa a apresentação automática de diapositivos';

  @override
  String slideOf(int index, int count) {
    return 'Diapositivo $index de $count';
  }

  @override
  String stepOf(int index, int count) {
    return 'Passo $index de $count';
  }

  @override
  String ratingValueOf(String value, String max) {
    return '$value de $max';
  }

  @override
  String get openCalendar => 'Abrir calendário';

  @override
  String get invalidDateFormat => 'Formato de data inválido.';

  @override
  String get dateOutOfRange => 'A data está fora do intervalo permitido.';

  @override
  String get fieldRequired => 'Este campo é obrigatório.';

  @override
  String get goToToday => 'Ir para hoje';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Mês seguinte';

  @override
  String get previousYear => 'Ano anterior';

  @override
  String get nextYear => 'Ano seguinte';

  @override
  String get previousYearRange => 'Intervalo de anos anterior';

  @override
  String get nextYearRange => 'Intervalo de anos seguinte';

  @override
  String monthPickerHeader(String caption) {
    return '$caption, alterar ano';
  }

  @override
  String yearPickerHeader(String caption) {
    return '$caption, alterar mês';
  }

  @override
  String selectedDate(String date) {
    return 'Data selecionada $date';
  }

  @override
  String todaysDate(String date) {
    return 'Data de hoje $date';
  }

  @override
  String weekNumber(String number) {
    return 'Semana $number';
  }

  @override
  String get chartNoData => 'O gráfico não tem dados para apresentar';

  @override
  String get chartNoDataAvailable => 'Não existem dados disponíveis';

  @override
  String get chartFallbackTitle => 'Gráfico. ';

  @override
  String chartAxisDescription(String axis, String subject) {
    return 'O eixo $axis apresenta $subject. ';
  }

  @override
  String get chartAxisX => 'X';

  @override
  String get chartAxisY => 'Y';

  @override
  String get chartAxisSecondaryY => 'Y secundário';

  @override
  String get chartAxisCategories => 'categorias';

  @override
  String get chartAxisTime => 'tempo';

  @override
  String get chartAxisValues => 'valores';

  @override
  String get chartLineLegendFallback => 'Linha';

  @override
  String funnelChartDescription(int count) {
    return 'Gráfico de funil com $count segmentos';
  }

  @override
  String donutChartDescription(int count) {
    return 'Gráfico de anel com $count fatias';
  }

  @override
  String gaugeChartDescription(int count) {
    return 'Gráfico de medidor com $count segmentos. ';
  }

  @override
  String gaugeCurrentValue(String value) {
    return 'Valor atual: $value';
  }

  @override
  String gaugeCurrentValueIs(String value) {
    return 'O valor atual é $value';
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
  String get gaugeUnknownSegment => 'Desconhecido';

  @override
  String ganttChartDescription(int count) {
    return 'Gráfico de Gantt com $count pontos de dados. ';
  }

  @override
  String heatMapChartDescription(int count) {
    return 'Gráfico de mapa de calor com $count pontos de dados. ';
  }

  @override
  String polarChartDescription(int count) {
    return 'Gráfico polar com $count séries de dados.';
  }

  @override
  String sparklineDescription(String label) {
    return 'Sparkline com a etiqueta $label';
  }

  @override
  String sankeyChartDescription(int nodes, int links) {
    return 'Gráfico de Sankey com $nodes nós e $links ligações';
  }

  @override
  String sankeyLinkFrom(String node) {
    return 'De $node';
  }

  @override
  String sankeyNodeDescription(String name, String weight) {
    return 'nó $name com peso $weight';
  }

  @override
  String sankeyLinkDescription(String source, String target, String weight) {
    return 'ligação de $source para $target com peso $weight';
  }

  @override
  String verticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras. ';
  }

  @override
  String verticalBarChartWithLineDescription(int count) {
    return 'Gráfico de barras verticais com $count barras e 1 linha. ';
  }

  @override
  String groupedVerticalBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas. ';
  }

  @override
  String groupedVerticalBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count séries de barras agrupadas e $lines séries de linhas. ';
  }

  @override
  String verticalStackedBarChartDescription(int count) {
    return 'Gráfico de barras verticais com $count barras empilhadas. ';
  }

  @override
  String verticalStackedBarChartWithLinesDescription(int count, int lines) {
    return 'Gráfico de barras verticais com $count barras empilhadas e $lines linhas. ';
  }

  @override
  String get presenceAvailable => 'Disponível';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceBusy => 'Ocupado';

  @override
  String get presenceDoNotDisturb => 'Não incomodar';

  @override
  String get presenceBlocked => 'Bloqueado';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get presenceOutOfOffice => 'Ausente do escritório';

  @override
  String get presenceUnknown => 'Desconhecido';

  @override
  String presenceOutOfOfficeStatus(String status) {
    return '$status, ausente do escritório';
  }
}
