import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The VegaDeclarativeChart docs page.
///
/// Sections, titles and sample data are upstream's, verbatim — all twenty-five
/// of the story's inline `ALL_SCHEMAS` entries are transcribed from the
/// Vega-Lite JSON it renders, key for key. The section's demo is delimited by a
/// `#docregion` whose id is the section id, so the "Show code" panel can read
/// this file back and print exactly the code that rendered.
const DocsPage vegaDeclarativeChartPage = DocsPage(
  id: 'charts-vegadeclarativechart',
  title: 'VegaDeclarativeChart',
  description: '',
  source: 'lib/pages/charts_vegadeclarativechart.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'charts-vegadeclarativechart--default',
      title: 'Default',
      description:
          'A comprehensive showcase of 25 Vega-Lite chart schemas covering '
          'real-world scenarios across Financial, Healthcare, Education, '
          'Manufacturing, Climate, Technology, Sports, and more domains. '
          'Demonstrates line, area, scatter, bar, donut, heatmap charts with '
          'various axis types, scales, and combo visualizations.',
      builder: _default,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'chartSchema',
      type: 'FluentVegaSchema',
      description: 'The specification to render.',
    ),
    PropRow(
      name: 'onSchemaChange',
      type: 'ValueChanged<FluentVegaSchema>?',
      defaultValue: 'null',
      description:
          'Called with the new schema whenever the legend selection changes.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentVegaDeclarativeChartStyle?',
      defaultValue: 'null',
      description: 'Overrides resolved style properties, highest precedence.',
    ),
    PropRow(
      name: 'errorBuilder',
      type: 'Widget Function(BuildContext, String)?',
      defaultValue: 'null',
      description:
          'Renders the failure surface for an unroutable specification.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          "The accessibility label for the whole chart. Defaults to the spec's "
          'own description.',
    ),
  ],
);

// #docregion charts-vegadeclarativechart--default
Widget _default(BuildContext context) => const _Default();

// Upstream's ALL_SCHEMAS: the twenty-five inline Vega-Lite specifications the
// picker walks, verbatim.
const Map<String, Map<String, Object?>>
_allSchemas = <String, Map<String, Object?>>{
  'adCtrScatter': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Ad click-through rate analysis',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'impressions': 50000,
          'clicks': 1250,
          'campaign': 'Summer Sale',
          'ctr': 2.5,
        },
        <String, Object?>{
          'impressions': 75000,
          'clicks': 2625,
          'campaign': 'Back to School',
          'ctr': 3.5,
        },
        <String, Object?>{
          'impressions': 120000,
          'clicks': 3600,
          'campaign': 'Holiday Special',
          'ctr': 3.0,
        },
        <String, Object?>{
          'impressions': 45000,
          'clicks': 1800,
          'campaign': 'Flash Deal',
          'ctr': 4.0,
        },
        <String, Object?>{
          'impressions': 90000,
          'clicks': 3150,
          'campaign': 'Spring Collection',
          'ctr': 3.5,
        },
        <String, Object?>{
          'impressions': 60000,
          'clicks': 1440,
          'campaign': 'Clearance',
          'ctr': 2.4,
        },
        <String, Object?>{
          'impressions': 100000,
          'clicks': 4500,
          'campaign': 'Black Friday',
          'ctr': 4.5,
        },
      ],
    },
    'mark': 'point',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'impressions',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Impressions', 'format': ',.0f'},
      },
      'y': <String, Object?>{
        'field': 'ctr',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Click-Through Rate (%)'},
      },
      'size': <String, Object?>{
        'field': 'clicks',
        'type': 'quantitative',
        'legend': <String, Object?>{'title': 'Total Clicks'},
        'scale': <String, Object?>{
          'range': <Object?>[100, 1000],
        },
      },
      'color': <String, Object?>{
        'field': 'ctr',
        'type': 'quantitative',
        'scale': <String, Object?>{'scheme': 'blues'},
        'legend': null,
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'campaign', 'type': 'nominal'},
        <String, Object?>{
          'field': 'impressions',
          'type': 'quantitative',
          'format': ',.0f',
        },
        <String, Object?>{
          'field': 'clicks',
          'type': 'quantitative',
          'format': ',.0f',
        },
        <String, Object?>{
          'field': 'ctr',
          'type': 'quantitative',
          'format': '.1f',
          'title': 'CTR %',
        },
      ],
    },
    'title': 'Ad Performance - CTR Analysis',
  },
  'ageDistributionBar': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Patient age distribution',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'ageGroup': '0-10', 'patients': 145},
        <String, Object?>{'ageGroup': '11-20', 'patients': 98},
        <String, Object?>{'ageGroup': '21-30', 'patients': 234},
        <String, Object?>{'ageGroup': '31-40', 'patients': 312},
        <String, Object?>{'ageGroup': '41-50', 'patients': 287},
        <String, Object?>{'ageGroup': '51-60', 'patients': 342},
        <String, Object?>{'ageGroup': '61-70', 'patients': 398},
        <String, Object?>{'ageGroup': '71-80', 'patients': 276},
        <String, Object?>{'ageGroup': '81+', 'patients': 189},
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'ageGroup',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Age Group', 'labelAngle': 0},
      },
      'y': <String, Object?>{
        'field': 'patients',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Number of Patients'},
      },
      'color': <String, Object?>{
        'field': 'patients',
        'type': 'quantitative',
        'scale': <String, Object?>{'scheme': 'teal'},
        'legend': null,
      },
    },
    'title': 'Patient Age Distribution',
  },
  'airQualityHeatmap': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Air quality index by location',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'city': 'New York', 'time': 'Morning', 'aqi': 45},
        <String, Object?>{'city': 'New York', 'time': 'Afternoon', 'aqi': 62},
        <String, Object?>{'city': 'New York', 'time': 'Evening', 'aqi': 58},
        <String, Object?>{'city': 'Los Angeles', 'time': 'Morning', 'aqi': 85},
        <String, Object?>{
          'city': 'Los Angeles',
          'time': 'Afternoon',
          'aqi': 95,
        },
        <String, Object?>{'city': 'Los Angeles', 'time': 'Evening', 'aqi': 78},
        <String, Object?>{'city': 'Chicago', 'time': 'Morning', 'aqi': 52},
        <String, Object?>{'city': 'Chicago', 'time': 'Afternoon', 'aqi': 68},
        <String, Object?>{'city': 'Chicago', 'time': 'Evening', 'aqi': 61},
        <String, Object?>{'city': 'Houston', 'time': 'Morning', 'aqi': 72},
        <String, Object?>{'city': 'Houston', 'time': 'Afternoon', 'aqi': 88},
        <String, Object?>{'city': 'Houston', 'time': 'Evening', 'aqi': 75},
      ],
    },
    'mark': 'rect',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'time',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Time of Day'},
      },
      'y': <String, Object?>{
        'field': 'city',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'City'},
      },
      'color': <String, Object?>{
        'field': 'aqi',
        'type': 'quantitative',
        'scale': <String, Object?>{
          'scheme': 'redyellowgreen',
          'domain': <Object?>[0, 150],
          'reverse': true,
        },
        'legend': <String, Object?>{'title': 'AQI'},
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'city', 'type': 'ordinal'},
        <String, Object?>{'field': 'time', 'type': 'ordinal'},
        <String, Object?>{
          'field': 'aqi',
          'type': 'quantitative',
          'title': 'Air Quality Index',
        },
      ],
    },
    'title': 'Air Quality Index Heatmap',
  },
  'apiResponseLine': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'API response time monitoring',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'timestamp': '2024-11-27T08:00:00',
          'responseTime': 145,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T09:00:00',
          'responseTime': 132,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T10:00:00',
          'responseTime': 158,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T11:00:00',
          'responseTime': 142,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T12:00:00',
          'responseTime': 178,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T13:00:00',
          'responseTime': 165,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T14:00:00',
          'responseTime': 152,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T15:00:00',
          'responseTime': 138,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T16:00:00',
          'responseTime': 148,
        },
        <String, Object?>{
          'timestamp': '2024-11-27T17:00:00',
          'responseTime': 156,
        },
      ],
    },
    'mark': <String, Object?>{'type': 'line', 'point': true, 'strokeWidth': 2},
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'timestamp',
        'type': 'temporal',
        'axis': <String, Object?>{'title': 'Time', 'format': '%H:%M'},
      },
      'y': <String, Object?>{
        'field': 'responseTime',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Response Time (ms)'},
      },
      'tooltip': <Object?>[
        <String, Object?>{
          'field': 'timestamp',
          'type': 'temporal',
          'format': '%H:%M',
        },
        <String, Object?>{
          'field': 'responseTime',
          'type': 'quantitative',
          'title': 'Response (ms)',
        },
      ],
    },
    'title': 'API Response Time Monitoring',
  },
  'areaMultiSeriesNoStack': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description':
        'Multiple area series without stacking - each fills to zero independently',
    'title': 'Department Performance - Overlapping Areas (No Stack)',
    'width': 600,
    'height': 300,
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'quarter': 'Q1 2024',
          'department': 'Sales',
          'performance': 85,
        },
        <String, Object?>{
          'quarter': 'Q1 2024',
          'department': 'Marketing',
          'performance': 70,
        },
        <String, Object?>{
          'quarter': 'Q1 2024',
          'department': 'Support',
          'performance': 60,
        },
        <String, Object?>{
          'quarter': 'Q2 2024',
          'department': 'Sales',
          'performance': 88,
        },
        <String, Object?>{
          'quarter': 'Q2 2024',
          'department': 'Marketing',
          'performance': 75,
        },
        <String, Object?>{
          'quarter': 'Q2 2024',
          'department': 'Support',
          'performance': 65,
        },
        <String, Object?>{
          'quarter': 'Q3 2024',
          'department': 'Sales',
          'performance': 92,
        },
        <String, Object?>{
          'quarter': 'Q3 2024',
          'department': 'Marketing',
          'performance': 82,
        },
        <String, Object?>{
          'quarter': 'Q3 2024',
          'department': 'Support',
          'performance': 70,
        },
        <String, Object?>{
          'quarter': 'Q4 2024',
          'department': 'Sales',
          'performance': 95,
        },
        <String, Object?>{
          'quarter': 'Q4 2024',
          'department': 'Marketing',
          'performance': 88,
        },
        <String, Object?>{
          'quarter': 'Q4 2024',
          'department': 'Support',
          'performance': 75,
        },
      ],
    },
    'mark': <String, Object?>{'type': 'area', 'fillOpacity': 0.5},
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'quarter',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Quarter'},
      },
      'y': <String, Object?>{
        'field': 'performance',
        'type': 'quantitative',
        'stack': null,
        'axis': <String, Object?>{'title': 'Performance Score'},
      },
      'color': <String, Object?>{
        'field': 'department',
        'type': 'nominal',
        'legend': <String, Object?>{'title': 'Department'},
      },
    },
  },
  'areaSingleTozeroy': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description':
        'Single series area chart with fill to zero baseline (tozeroy mode)',
    'title': 'Monthly Revenue - Single Series (Fill to Zero)',
    'width': 600,
    'height': 300,
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'month': '2024-01', 'revenue': 12000},
        <String, Object?>{'month': '2024-02', 'revenue': 15000},
        <String, Object?>{'month': '2024-03', 'revenue': 18000},
        <String, Object?>{'month': '2024-04', 'revenue': 16000},
        <String, Object?>{'month': '2024-05', 'revenue': 22000},
        <String, Object?>{'month': '2024-06', 'revenue': 25000},
        <String, Object?>{'month': '2024-07', 'revenue': 28000},
        <String, Object?>{'month': '2024-08', 'revenue': 26000},
        <String, Object?>{'month': '2024-09', 'revenue': 30000},
        <String, Object?>{'month': '2024-10', 'revenue': 32000},
        <String, Object?>{'month': '2024-11', 'revenue': 35000},
        <String, Object?>{'month': '2024-12', 'revenue': 38000},
      ],
    },
    'mark': 'area',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'month',
        'type': 'temporal',
        'axis': <String, Object?>{'title': 'Month', 'format': '%b %Y'},
      },
      'y': <String, Object?>{
        'field': 'revenue',
        'type': 'quantitative',
        'stack': null,
        'axis': <String, Object?>{'title': 'Revenue (\$)', 'format': '\$,.0f'},
      },
    },
  },
  'areaStackedTonexty': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Stacked area chart with multiple series (tonexty mode)',
    'title': 'Product Sales by Category - Stacked Areas',
    'width': 600,
    'height': 300,
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'month': '2024-01',
          'category': 'Electronics',
          'sales': 5000,
        },
        <String, Object?>{
          'month': '2024-01',
          'category': 'Clothing',
          'sales': 3000,
        },
        <String, Object?>{
          'month': '2024-01',
          'category': 'Home',
          'sales': 2000,
        },
        <String, Object?>{
          'month': '2024-02',
          'category': 'Electronics',
          'sales': 5500,
        },
        <String, Object?>{
          'month': '2024-02',
          'category': 'Clothing',
          'sales': 3500,
        },
        <String, Object?>{
          'month': '2024-02',
          'category': 'Home',
          'sales': 2200,
        },
        <String, Object?>{
          'month': '2024-03',
          'category': 'Electronics',
          'sales': 6000,
        },
        <String, Object?>{
          'month': '2024-03',
          'category': 'Clothing',
          'sales': 4000,
        },
        <String, Object?>{
          'month': '2024-03',
          'category': 'Home',
          'sales': 2500,
        },
        <String, Object?>{
          'month': '2024-04',
          'category': 'Electronics',
          'sales': 5800,
        },
        <String, Object?>{
          'month': '2024-04',
          'category': 'Clothing',
          'sales': 3800,
        },
        <String, Object?>{
          'month': '2024-04',
          'category': 'Home',
          'sales': 2300,
        },
        <String, Object?>{
          'month': '2024-05',
          'category': 'Electronics',
          'sales': 6500,
        },
        <String, Object?>{
          'month': '2024-05',
          'category': 'Clothing',
          'sales': 4200,
        },
        <String, Object?>{
          'month': '2024-05',
          'category': 'Home',
          'sales': 2700,
        },
        <String, Object?>{
          'month': '2024-06',
          'category': 'Electronics',
          'sales': 7000,
        },
        <String, Object?>{
          'month': '2024-06',
          'category': 'Clothing',
          'sales': 4500,
        },
        <String, Object?>{
          'month': '2024-06',
          'category': 'Home',
          'sales': 3000,
        },
        <String, Object?>{
          'month': '2024-07',
          'category': 'Electronics',
          'sales': 7500,
        },
        <String, Object?>{
          'month': '2024-07',
          'category': 'Clothing',
          'sales': 5000,
        },
        <String, Object?>{
          'month': '2024-07',
          'category': 'Home',
          'sales': 3200,
        },
        <String, Object?>{
          'month': '2024-08',
          'category': 'Electronics',
          'sales': 7200,
        },
        <String, Object?>{
          'month': '2024-08',
          'category': 'Clothing',
          'sales': 4800,
        },
        <String, Object?>{
          'month': '2024-08',
          'category': 'Home',
          'sales': 3000,
        },
        <String, Object?>{
          'month': '2024-09',
          'category': 'Electronics',
          'sales': 8000,
        },
        <String, Object?>{
          'month': '2024-09',
          'category': 'Clothing',
          'sales': 5500,
        },
        <String, Object?>{
          'month': '2024-09',
          'category': 'Home',
          'sales': 3500,
        },
        <String, Object?>{
          'month': '2024-10',
          'category': 'Electronics',
          'sales': 8500,
        },
        <String, Object?>{
          'month': '2024-10',
          'category': 'Clothing',
          'sales': 6000,
        },
        <String, Object?>{
          'month': '2024-10',
          'category': 'Home',
          'sales': 3800,
        },
        <String, Object?>{
          'month': '2024-11',
          'category': 'Electronics',
          'sales': 9000,
        },
        <String, Object?>{
          'month': '2024-11',
          'category': 'Clothing',
          'sales': 6500,
        },
        <String, Object?>{
          'month': '2024-11',
          'category': 'Home',
          'sales': 4000,
        },
        <String, Object?>{
          'month': '2024-12',
          'category': 'Electronics',
          'sales': 9500,
        },
        <String, Object?>{
          'month': '2024-12',
          'category': 'Clothing',
          'sales': 7000,
        },
        <String, Object?>{
          'month': '2024-12',
          'category': 'Home',
          'sales': 4500,
        },
      ],
    },
    'mark': 'area',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'month',
        'type': 'temporal',
        'axis': <String, Object?>{'title': 'Month', 'format': '%b'},
      },
      'y': <String, Object?>{
        'field': 'sales',
        'type': 'quantitative',
        'stack': 'zero',
        'axis': <String, Object?>{'title': 'Sales (\$)', 'format': '\$,.0f'},
      },
      'color': <String, Object?>{
        'field': 'category',
        'type': 'nominal',
        'legend': <String, Object?>{'title': 'Product Category'},
      },
    },
  },
  'areachart': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Area chart with temporal data.',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'date': '2023-01-01', 'value': 28, 'category': 'A'},
        <String, Object?>{'date': '2023-01-02', 'value': 55, 'category': 'A'},
        <String, Object?>{'date': '2023-01-03', 'value': 43, 'category': 'A'},
        <String, Object?>{'date': '2023-01-04', 'value': 91, 'category': 'A'},
        <String, Object?>{'date': '2023-01-05', 'value': 81, 'category': 'A'},
        <String, Object?>{'date': '2023-01-01', 'value': 20, 'category': 'B'},
        <String, Object?>{'date': '2023-01-02', 'value': 40, 'category': 'B'},
        <String, Object?>{'date': '2023-01-03', 'value': 30, 'category': 'B'},
        <String, Object?>{'date': '2023-01-04', 'value': 70, 'category': 'B'},
        <String, Object?>{'date': '2023-01-05', 'value': 60, 'category': 'B'},
      ],
    },
    'mark': 'area',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'date',
        'type': 'temporal',
        'axis': <String, Object?>{'title': 'Date'},
      },
      'y': <String, Object?>{
        'field': 'value',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Value'},
      },
      'color': <String, Object?>{'field': 'category', 'type': 'nominal'},
    },
    'title': 'Simple Area Chart',
  },
  'attendanceBar': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Stadium attendance figures',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'game': 'Game 1', 'attendance': 42500},
        <String, Object?>{'game': 'Game 2', 'attendance': 45200},
        <String, Object?>{'game': 'Game 3', 'attendance': 38900},
        <String, Object?>{'game': 'Game 4', 'attendance': 51000},
        <String, Object?>{'game': 'Game 5', 'attendance': 48700},
        <String, Object?>{'game': 'Game 6', 'attendance': 52500},
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'game',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Game'},
      },
      'y': <String, Object?>{
        'field': 'attendance',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Attendance', 'format': ',.0f'},
      },
      'color': <String, Object?>{
        'field': 'attendance',
        'type': 'quantitative',
        'scale': <String, Object?>{'scheme': 'oranges'},
        'legend': null,
      },
    },
    'title': 'Home Game Attendance',
  },
  'attendanceHeatmap': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Class attendance patterns',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'day': 'Monday',
          'period': 'Period 1',
          'attendance': 92,
        },
        <String, Object?>{
          'day': 'Monday',
          'period': 'Period 2',
          'attendance': 89,
        },
        <String, Object?>{
          'day': 'Monday',
          'period': 'Period 3',
          'attendance': 87,
        },
        <String, Object?>{
          'day': 'Monday',
          'period': 'Period 4',
          'attendance': 85,
        },
        <String, Object?>{
          'day': 'Tuesday',
          'period': 'Period 1',
          'attendance': 90,
        },
        <String, Object?>{
          'day': 'Tuesday',
          'period': 'Period 2',
          'attendance': 88,
        },
        <String, Object?>{
          'day': 'Tuesday',
          'period': 'Period 3',
          'attendance': 91,
        },
        <String, Object?>{
          'day': 'Tuesday',
          'period': 'Period 4',
          'attendance': 86,
        },
        <String, Object?>{
          'day': 'Wednesday',
          'period': 'Period 1',
          'attendance': 94,
        },
        <String, Object?>{
          'day': 'Wednesday',
          'period': 'Period 2',
          'attendance': 92,
        },
        <String, Object?>{
          'day': 'Wednesday',
          'period': 'Period 3',
          'attendance': 90,
        },
        <String, Object?>{
          'day': 'Wednesday',
          'period': 'Period 4',
          'attendance': 88,
        },
        <String, Object?>{
          'day': 'Thursday',
          'period': 'Period 1',
          'attendance': 91,
        },
        <String, Object?>{
          'day': 'Thursday',
          'period': 'Period 2',
          'attendance': 89,
        },
        <String, Object?>{
          'day': 'Thursday',
          'period': 'Period 3',
          'attendance': 87,
        },
        <String, Object?>{
          'day': 'Thursday',
          'period': 'Period 4',
          'attendance': 84,
        },
        <String, Object?>{
          'day': 'Friday',
          'period': 'Period 1',
          'attendance': 88,
        },
        <String, Object?>{
          'day': 'Friday',
          'period': 'Period 2',
          'attendance': 85,
        },
        <String, Object?>{
          'day': 'Friday',
          'period': 'Period 3',
          'attendance': 83,
        },
        <String, Object?>{
          'day': 'Friday',
          'period': 'Period 4',
          'attendance': 79,
        },
      ],
    },
    'mark': 'rect',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'day',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Day of Week'},
      },
      'y': <String, Object?>{
        'field': 'period',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Class Period'},
      },
      'color': <String, Object?>{
        'field': 'attendance',
        'type': 'quantitative',
        'scale': <String, Object?>{'scheme': 'blues'},
        'legend': <String, Object?>{'title': 'Attendance %'},
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'day', 'type': 'ordinal'},
        <String, Object?>{'field': 'period', 'type': 'ordinal'},
        <String, Object?>{
          'field': 'attendance',
          'type': 'quantitative',
          'title': 'Attendance %',
          'format': '.0f',
        },
      ],
    },
    'title': 'Weekly Attendance Patterns',
  },
  'bandwidthStackedArea': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Network bandwidth usage',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'hour': '2024-11-27T00:00:00',
          'inbound': 125,
          'outbound': 95,
        },
        <String, Object?>{
          'hour': '2024-11-27T04:00:00',
          'inbound': 85,
          'outbound': 65,
        },
        <String, Object?>{
          'hour': '2024-11-27T08:00:00',
          'inbound': 245,
          'outbound': 185,
        },
        <String, Object?>{
          'hour': '2024-11-27T12:00:00',
          'inbound': 385,
          'outbound': 295,
        },
        <String, Object?>{
          'hour': '2024-11-27T16:00:00',
          'inbound': 425,
          'outbound': 325,
        },
        <String, Object?>{
          'hour': '2024-11-27T20:00:00',
          'inbound': 285,
          'outbound': 215,
        },
      ],
    },
    'transform': <Object?>[
      <String, Object?>{
        'fold': <Object?>['inbound', 'outbound'],
        'as': <Object?>['direction', 'bandwidth'],
      },
    ],
    'mark': 'area',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'hour',
        'type': 'temporal',
        'axis': <String, Object?>{'title': 'Hour', 'format': '%H:%M'},
      },
      'y': <String, Object?>{
        'field': 'bandwidth',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Bandwidth (Mbps)'},
      },
      'color': <String, Object?>{
        'field': 'direction',
        'type': 'nominal',
        'legend': <String, Object?>{'title': 'Direction'},
      },
      'opacity': <String, Object?>{'value': 0.7},
    },
    'title': 'Network Bandwidth Usage',
  },
  'barchart': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'A simple bar chart.',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'category': 'A', 'value': 28},
        <String, Object?>{'category': 'B', 'value': 55},
        <String, Object?>{'category': 'C', 'value': 43},
        <String, Object?>{'category': 'D', 'value': 91},
        <String, Object?>{'category': 'E', 'value': 81},
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'value',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Value'},
      },
      'y': <String, Object?>{
        'field': 'category',
        'type': 'nominal',
        'axis': <String, Object?>{'title': 'Category'},
      },
    },
    'title': 'Horizontal Bar Chart',
  },
  'biodiversityGrouped': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Biodiversity counts by region',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'region': 'Amazon',
          'category': 'Mammals',
          'count': 427,
        },
        <String, Object?>{
          'region': 'Amazon',
          'category': 'Birds',
          'count': 1300,
        },
        <String, Object?>{
          'region': 'Amazon',
          'category': 'Reptiles',
          'count': 378,
        },
        <String, Object?>{
          'region': 'Congo',
          'category': 'Mammals',
          'count': 268,
        },
        <String, Object?>{'region': 'Congo', 'category': 'Birds', 'count': 700},
        <String, Object?>{
          'region': 'Congo',
          'category': 'Reptiles',
          'count': 280,
        },
        <String, Object?>{
          'region': 'Borneo',
          'category': 'Mammals',
          'count': 222,
        },
        <String, Object?>{
          'region': 'Borneo',
          'category': 'Birds',
          'count': 420,
        },
        <String, Object?>{
          'region': 'Borneo',
          'category': 'Reptiles',
          'count': 254,
        },
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'region',
        'type': 'nominal',
        'axis': <String, Object?>{'title': 'Region'},
      },
      'y': <String, Object?>{
        'field': 'count',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Species Count'},
      },
      'color': <String, Object?>{
        'field': 'category',
        'type': 'nominal',
        'legend': <String, Object?>{'title': 'Category'},
      },
      'xOffset': <String, Object?>{'field': 'category'},
    },
    'title': 'Biodiversity by Rainforest Region',
  },
  'bmiScatter': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'BMI distribution analysis',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'height': 160,
          'weight': 52,
          'bmi': 20.3,
          'category': 'Normal',
        },
        <String, Object?>{
          'height': 165,
          'weight': 68,
          'bmi': 25.0,
          'category': 'Overweight',
        },
        <String, Object?>{
          'height': 170,
          'weight': 75,
          'bmi': 25.9,
          'category': 'Overweight',
        },
        <String, Object?>{
          'height': 175,
          'weight': 70,
          'bmi': 22.9,
          'category': 'Normal',
        },
        <String, Object?>{
          'height': 180,
          'weight': 95,
          'bmi': 29.3,
          'category': 'Overweight',
        },
        <String, Object?>{
          'height': 158,
          'weight': 45,
          'bmi': 18.0,
          'category': 'Underweight',
        },
        <String, Object?>{
          'height': 172,
          'weight': 82,
          'bmi': 27.7,
          'category': 'Overweight',
        },
        <String, Object?>{
          'height': 168,
          'weight': 58,
          'bmi': 20.5,
          'category': 'Normal',
        },
        <String, Object?>{
          'height': 177,
          'weight': 88,
          'bmi': 28.1,
          'category': 'Overweight',
        },
        <String, Object?>{
          'height': 162,
          'weight': 48,
          'bmi': 18.3,
          'category': 'Underweight',
        },
      ],
    },
    'mark': 'point',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'height',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Height (cm)'},
      },
      'y': <String, Object?>{
        'field': 'weight',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Weight (kg)'},
      },
      'color': <String, Object?>{
        'field': 'category',
        'type': 'nominal',
        'scale': <String, Object?>{
          'domain': <Object?>['Underweight', 'Normal', 'Overweight'],
          'range': <Object?>['#ff7f0e', '#2ca02c', '#d62728'],
        },
        'legend': <String, Object?>{'title': 'BMI Category'},
      },
      'size': <String, Object?>{'value': 100},
      'tooltip': <Object?>[
        <String, Object?>{
          'field': 'height',
          'type': 'quantitative',
          'title': 'Height (cm)',
        },
        <String, Object?>{
          'field': 'weight',
          'type': 'quantitative',
          'title': 'Weight (kg)',
        },
        <String, Object?>{
          'field': 'bmi',
          'type': 'quantitative',
          'title': 'BMI',
          'format': '.1f',
        },
        <String, Object?>{
          'field': 'category',
          'type': 'nominal',
          'title': 'Category',
        },
      ],
    },
    'title': 'BMI Distribution Scatter',
  },
  'budgetActualGrouped': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Budget vs Actual spending by department',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'department': 'Marketing',
          'category': 'Budget',
          'amount': 250000,
        },
        <String, Object?>{
          'department': 'Marketing',
          'category': 'Actual',
          'amount': 235000,
        },
        <String, Object?>{
          'department': 'Engineering',
          'category': 'Budget',
          'amount': 450000,
        },
        <String, Object?>{
          'department': 'Engineering',
          'category': 'Actual',
          'amount': 478000,
        },
        <String, Object?>{
          'department': 'Sales',
          'category': 'Budget',
          'amount': 320000,
        },
        <String, Object?>{
          'department': 'Sales',
          'category': 'Actual',
          'amount': 310000,
        },
        <String, Object?>{
          'department': 'Operations',
          'category': 'Budget',
          'amount': 180000,
        },
        <String, Object?>{
          'department': 'Operations',
          'category': 'Actual',
          'amount': 192000,
        },
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'department',
        'type': 'nominal',
        'axis': <String, Object?>{'title': 'Department'},
      },
      'y': <String, Object?>{
        'field': 'amount',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Amount (\$)', 'format': '\$,.0f'},
      },
      'color': <String, Object?>{
        'field': 'category',
        'type': 'nominal',
        'scale': <String, Object?>{
          'domain': <Object?>['Budget', 'Actual'],
          'range': <Object?>['#1f77b4', '#ff7f0e'],
        },
      },
      'xOffset': <String, Object?>{'field': 'category'},
    },
    'title': 'Budget vs Actual - Department Comparison',
  },
  'bugPriorityDonut': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Bug priority distribution',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'priority': 'Critical', 'count': 12},
        <String, Object?>{'priority': 'High', 'count': 28},
        <String, Object?>{'priority': 'Medium', 'count': 45},
        <String, Object?>{'priority': 'Low', 'count': 67},
      ],
    },
    'mark': <String, Object?>{'type': 'arc', 'innerRadius': 55},
    'encoding': <String, Object?>{
      'theta': <String, Object?>{'field': 'count', 'type': 'quantitative'},
      'color': <String, Object?>{
        'field': 'priority',
        'type': 'nominal',
        'scale': <String, Object?>{
          'domain': <Object?>['Critical', 'High', 'Medium', 'Low'],
          'range': <Object?>['#d62728', '#ff7f0e', '#ffcc00', '#2ca02c'],
        },
        'legend': <String, Object?>{'title': 'Priority'},
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'priority', 'type': 'nominal'},
        <String, Object?>{
          'field': 'count',
          'type': 'quantitative',
          'title': 'Open Bugs',
        },
      ],
    },
    'title': 'Open Bugs by Priority',
  },
  'campaignPerformanceCombo': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Marketing campaign performance',
    'layer': <Object?>[
      <String, Object?>{
        'mark': 'bar',
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'week',
            'type': 'temporal',
            'axis': <String, Object?>{'title': 'Week', 'format': '%b %d'},
          },
          'y': <String, Object?>{
            'field': 'spend',
            'type': 'quantitative',
            'axis': <String, Object?>{
              'title': 'Spend (\$)',
              'format': '\$,.0f',
            },
          },
          'color': <String, Object?>{'value': 'lightblue'},
        },
      },
      <String, Object?>{
        'mark': <String, Object?>{
          'type': 'line',
          'point': true,
          'color': 'darkgreen',
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'week', 'type': 'temporal'},
          'y': <String, Object?>{
            'field': 'conversions',
            'type': 'quantitative',
            'axis': <String, Object?>{'title': 'Conversions'},
          },
        },
      },
    ],

    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'week': '2024-10-01',
          'spend': 12000,
          'conversions': 240,
        },
        <String, Object?>{
          'week': '2024-10-08',
          'spend': 15000,
          'conversions': 315,
        },
        <String, Object?>{
          'week': '2024-10-15',
          'spend': 18000,
          'conversions': 378,
        },
        <String, Object?>{
          'week': '2024-10-22',
          'spend': 14000,
          'conversions': 294,
        },
        <String, Object?>{
          'week': '2024-10-29',
          'spend': 16000,
          'conversions': 336,
        },
        <String, Object?>{
          'week': '2024-11-05',
          'spend': 20000,
          'conversions': 440,
        },
      ],
    },
    'resolve': <String, Object?>{
      'scale': <String, Object?>{'y': 'independent'},
    },
    'title': 'Campaign Spend vs Conversions',
  },
  'cashflowCombo': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Monthly cash flow analysis',
    'layer': <Object?>[
      <String, Object?>{
        'mark': 'bar',
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'month',
            'type': 'temporal',
            'axis': <String, Object?>{'title': 'Month', 'format': '%b'},
          },
          'y': <String, Object?>{
            'field': 'cashflow',
            'type': 'quantitative',
            'axis': <String, Object?>{
              'title': 'Cash Flow (\$)',
              'format': '\$,.0f',
            },
          },
          'color': <String, Object?>{
            'condition': <String, Object?>{
              'test': 'datum.cashflow > 0',
              'value': '#2ca02c',
            },
            'value': '#d62728',
          },
        },
      },
      <String, Object?>{
        'mark': <String, Object?>{
          'type': 'line',
          'point': true,
          'color': 'orange',
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'month', 'type': 'temporal'},
          'y': <String, Object?>{
            'field': 'balance',
            'type': 'quantitative',
            'axis': <String, Object?>{'title': 'Running Balance'},
          },
        },
      },
    ],

    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'month': '2024-01',
          'cashflow': 85000,
          'balance': 285000,
        },
        <String, Object?>{
          'month': '2024-02',
          'cashflow': -42000,
          'balance': 243000,
        },
        <String, Object?>{
          'month': '2024-03',
          'cashflow': 95000,
          'balance': 338000,
        },
        <String, Object?>{
          'month': '2024-04',
          'cashflow': 112000,
          'balance': 450000,
        },
        <String, Object?>{
          'month': '2024-05',
          'cashflow': -28000,
          'balance': 422000,
        },
        <String, Object?>{
          'month': '2024-06',
          'cashflow': 138000,
          'balance': 560000,
        },
      ],
    },
    'resolve': <String, Object?>{
      'scale': <String, Object?>{'y': 'independent'},
    },
    'title': 'Cash Flow Analysis',
  },
  'categorySalesStacked': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Category sales breakdown',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'quarter': 'Q1',
          'category': 'Electronics',
          'sales': 125000,
        },
        <String, Object?>{
          'quarter': 'Q1',
          'category': 'Clothing',
          'sales': 78000,
        },
        <String, Object?>{
          'quarter': 'Q1',
          'category': 'Home & Garden',
          'sales': 52000,
        },
        <String, Object?>{
          'quarter': 'Q1',
          'category': 'Sports',
          'sales': 38000,
        },
        <String, Object?>{
          'quarter': 'Q2',
          'category': 'Electronics',
          'sales': 142000,
        },
        <String, Object?>{
          'quarter': 'Q2',
          'category': 'Clothing',
          'sales': 95000,
        },
        <String, Object?>{
          'quarter': 'Q2',
          'category': 'Home & Garden',
          'sales': 68000,
        },
        <String, Object?>{
          'quarter': 'Q2',
          'category': 'Sports',
          'sales': 45000,
        },
        <String, Object?>{
          'quarter': 'Q3',
          'category': 'Electronics',
          'sales': 138000,
        },
        <String, Object?>{
          'quarter': 'Q3',
          'category': 'Clothing',
          'sales': 88000,
        },
        <String, Object?>{
          'quarter': 'Q3',
          'category': 'Home & Garden',
          'sales': 61000,
        },
        <String, Object?>{
          'quarter': 'Q3',
          'category': 'Sports',
          'sales': 52000,
        },
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'quarter',
        'type': 'nominal',
        'axis': <String, Object?>{'title': 'Quarter'},
      },
      'y': <String, Object?>{
        'field': 'sales',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Sales (\$)', 'format': '\$,.0f'},
      },
      'color': <String, Object?>{
        'field': 'category',
        'type': 'nominal',
        'legend': <String, Object?>{'title': 'Category'},
      },
    },
    'title': 'Category Sales - Stacked View',
  },
  'channelDistributionDonut': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Marketing channel distribution',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'channel': 'Email', 'budget': 45000},
        <String, Object?>{'channel': 'Social Media', 'budget': 85000},
        <String, Object?>{'channel': 'Search Ads', 'budget': 120000},
        <String, Object?>{'channel': 'Display Ads', 'budget': 65000},
        <String, Object?>{'channel': 'Content Marketing', 'budget': 55000},
        <String, Object?>{'channel': 'Influencer', 'budget': 75000},
      ],
    },
    'mark': <String, Object?>{
      'type': 'arc',
      'innerRadius': 60,
      'padAngle': 0.015,
    },
    'encoding': <String, Object?>{
      'theta': <String, Object?>{'field': 'budget', 'type': 'quantitative'},
      'color': <String, Object?>{
        'field': 'channel',
        'type': 'nominal',
        'scale': <String, Object?>{'scheme': 'set2'},
        'legend': <String, Object?>{'title': 'Marketing Channel'},
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'channel', 'type': 'nominal'},
        <String, Object?>{
          'field': 'budget',
          'type': 'quantitative',
          'format': '\$,.0f',
          'title': 'Budget',
        },
      ],
    },
    'title': 'Marketing Budget by Channel',
  },
  'climateZonesScatter': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Climate zone temperature distribution',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{
          'avgTemp': -15,
          'precipitation': 250,
          'zone': 'Arctic',
        },
        <String, Object?>{
          'avgTemp': 5,
          'precipitation': 800,
          'zone': 'Temperate',
        },
        <String, Object?>{
          'avgTemp': 15,
          'precipitation': 650,
          'zone': 'Subtropical',
        },
        <String, Object?>{
          'avgTemp': 25,
          'precipitation': 2000,
          'zone': 'Tropical',
        },
        <String, Object?>{
          'avgTemp': -8,
          'precipitation': 300,
          'zone': 'Subarctic',
        },
        <String, Object?>{'avgTemp': 22, 'precipitation': 450, 'zone': 'Arid'},
        <String, Object?>{
          'avgTemp': 18,
          'precipitation': 900,
          'zone': 'Mediterranean',
        },
      ],
    },
    'mark': <String, Object?>{'type': 'point', 'size': 200},
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'avgTemp',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Average Temperature (°C)'},
      },
      'y': <String, Object?>{
        'field': 'precipitation',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Annual Precipitation (mm)'},
      },
      'color': <String, Object?>{
        'field': 'zone',
        'type': 'nominal',
        'legend': <String, Object?>{'title': 'Climate Zone'},
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'zone', 'type': 'nominal', 'title': 'Zone'},
        <String, Object?>{
          'field': 'avgTemp',
          'type': 'quantitative',
          'title': 'Avg Temp (°C)',
        },
        <String, Object?>{
          'field': 'precipitation',
          'type': 'quantitative',
          'title': 'Precipitation (mm)',
        },
      ],
    },
    'title': 'Climate Zones Classification',
  },
  'co2EmissionsArea': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'CO2 emissions over time',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'year': '1990', 'emissions': 22.7},
        <String, Object?>{'year': '1995', 'emissions': 23.5},
        <String, Object?>{'year': '2000', 'emissions': 25.1},
        <String, Object?>{'year': '2005', 'emissions': 28.8},
        <String, Object?>{'year': '2010', 'emissions': 32.5},
        <String, Object?>{'year': '2015', 'emissions': 35.2},
        <String, Object?>{'year': '2020', 'emissions': 33.8},
        <String, Object?>{'year': '2023', 'emissions': 36.1},
      ],
    },
    'mark': <String, Object?>{
      'type': 'area',
      'line': true,
      'point': true,
      'color': 'gray',
      'opacity': 0.7,
    },
    'encoding': <String, Object?>{
      'x': <String, Object?>{
        'field': 'year',
        'type': 'ordinal',
        'axis': <String, Object?>{'title': 'Year'},
      },
      'y': <String, Object?>{
        'field': 'emissions',
        'type': 'quantitative',
        'axis': <String, Object?>{
          'title': 'CO₂ Emissions (Gt)',
          'format': '.1f',
        },
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'year', 'type': 'ordinal'},
        <String, Object?>{
          'field': 'emissions',
          'type': 'quantitative',
          'title': 'Emissions (Gt)',
          'format': '.1f',
        },
      ],
    },
    'title': 'Global CO₂ Emissions Trend',
  },
  'codeCommitsCombo': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Code commit activity',
    'layer': <Object?>[
      <String, Object?>{
        'mark': 'bar',
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'week',
            'type': 'ordinal',
            'axis': <String, Object?>{'title': 'Week'},
          },
          'y': <String, Object?>{
            'field': 'commits',
            'type': 'quantitative',
            'axis': <String, Object?>{'title': 'Commits'},
          },
          'color': <String, Object?>{'value': 'lightcoral'},
        },
      },
      <String, Object?>{
        'mark': <String, Object?>{
          'type': 'line',
          'point': true,
          'color': 'navy',
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'week', 'type': 'ordinal'},
          'y': <String, Object?>{
            'field': 'contributors',
            'type': 'quantitative',
            'axis': <String, Object?>{'title': 'Active Contributors'},
          },
        },
      },
    ],

    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'week': 'Week 1', 'commits': 142, 'contributors': 12},
        <String, Object?>{'week': 'Week 2', 'commits': 158, 'contributors': 14},
        <String, Object?>{'week': 'Week 3', 'commits': 135, 'contributors': 11},
        <String, Object?>{'week': 'Week 4', 'commits': 178, 'contributors': 15},
        <String, Object?>{'week': 'Week 5', 'commits': 165, 'contributors': 13},
        <String, Object?>{'week': 'Week 6', 'commits': 192, 'contributors': 16},
      ],
    },
    'resolve': <String, Object?>{
      'scale': <String, Object?>{'y': 'independent'},
    },
    'title': 'Code Commits & Contributors',
  },
  'conversionFunnel': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'E-commerce conversion funnel',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'stage': 'Page Views', 'count': 50000},
        <String, Object?>{'stage': 'Product Views', 'count': 12500},
        <String, Object?>{'stage': 'Add to Cart', 'count': 3750},
        <String, Object?>{'stage': 'Checkout Started', 'count': 2250},
        <String, Object?>{'stage': 'Payment Info', 'count': 1800},
        <String, Object?>{'stage': 'Order Completed', 'count': 1575},
      ],
    },
    'mark': 'bar',
    'encoding': <String, Object?>{
      'y': <String, Object?>{
        'field': 'stage',
        'type': 'nominal',
        'axis': <String, Object?>{'title': 'Funnel Stage'},
        'sort': null,
      },
      'x': <String, Object?>{
        'field': 'count',
        'type': 'quantitative',
        'axis': <String, Object?>{'title': 'Users', 'format': ',.0f'},
      },
      'color': <String, Object?>{
        'field': 'count',
        'type': 'quantitative',
        'scale': <String, Object?>{'scheme': 'blues'},
        'legend': null,
      },
    },
    'title': 'Conversion Funnel Analysis',
  },
  'courseEnrollmentDonut': <String, Object?>{
    '\$schema': 'https://vega.github.io/schema/vega-lite/v5.json',
    'description': 'Course enrollment breakdown',
    'data': <String, Object?>{
      'values': <Object?>[
        <String, Object?>{'course': 'Computer Science', 'enrolled': 450},
        <String, Object?>{'course': 'Engineering', 'enrolled': 380},
        <String, Object?>{'course': 'Business', 'enrolled': 520},
        <String, Object?>{'course': 'Arts & Humanities', 'enrolled': 290},
        <String, Object?>{'course': 'Natural Sciences', 'enrolled': 360},
        <String, Object?>{'course': 'Social Sciences', 'enrolled': 310},
      ],
    },
    'mark': <String, Object?>{
      'type': 'arc',
      'innerRadius': 65,
      'padAngle': 0.01,
    },
    'encoding': <String, Object?>{
      'theta': <String, Object?>{'field': 'enrolled', 'type': 'quantitative'},
      'color': <String, Object?>{
        'field': 'course',
        'type': 'nominal',
        'scale': <String, Object?>{'scheme': 'category20'},
        'legend': <String, Object?>{'title': 'Course'},
      },
      'tooltip': <Object?>[
        <String, Object?>{'field': 'course', 'type': 'nominal'},
        <String, Object?>{
          'field': 'enrolled',
          'type': 'quantitative',
          'title': 'Students',
          'format': ',.0f',
        },
      ],
    },
    'title': 'Course Enrollment Distribution',
  },
};

// `categorizeSchemas()` with its answer already worked out. Upstream derives
// this by matching every key against a table of category keywords and then
// sorting the result into `categoryOrder`; the table is routing machinery
// rather than anything the page renders, so the port keeps the outcome and
// skips the loop. Manufacturing and Sports match nothing here, which is why
// upstream's list prints nine rows and not eleven.
const Map<String, List<String>> _schemaCategories = <String, List<String>>{
  'Basic Charts': <String>['areachart', 'barchart'],
  'Financial': <String>['budgetActualGrouped', 'cashflowCombo'],
  'E-Commerce': <String>['categorySalesStacked', 'conversionFunnel'],
  'Marketing': <String>[
    'adCtrScatter',
    'campaignPerformanceCombo',
    'channelDistributionDonut',
  ],
  'Healthcare': <String>['ageDistributionBar', 'bmiScatter'],
  'Education': <String>[
    'attendanceBar',
    'attendanceHeatmap',
    'courseEnrollmentDonut',
  ],
  'Climate': <String>[
    'airQualityHeatmap',
    'biodiversityGrouped',
    'climateZonesScatter',
    'co2EmissionsArea',
  ],
  'Technology': <String>[
    'apiResponseLine',
    'bandwidthStackedArea',
    'bugPriorityDonut',
    'codeCommitsCombo',
  ],
  'Other': <String>[
    'areaMultiSeriesNoStack',
    'areaSingleTozeroy',
    'areaStackedTonexty',
  ],
};

// The nine rows upstream lists under "Features Supported:".
const List<(String, String)> _features = <(String, String)>[
  ('Line Charts:', 'Temporal or quantitative x-axis with multiple series'),
  ('Area Charts:', 'Filled line charts for showing trends'),
  ('Scatter Charts:', 'Point marks with optional size encoding'),
  (
    'Bar Charts:',
    'Horizontal and vertical bar visualizations, stacked and grouped',
  ),
  ('Donut Charts:', 'Arc marks with innerRadius for donut effect'),
  ('Heatmaps:', 'Rect marks with color scale'),
  ('Combo Charts:', 'Layered visualizations (line + bar, line + area, etc.)'),
  ('Scale Types:', 'Linear, logarithmic, temporal, ordinal, nominal'),
  ('Transforms:', 'Data transformations like fold for reshaping'),
];

// The option text upstream builds from a key: split on `-` and `_`, capitalise
// each word, join with spaces. None of the twenty-five keys carries either
// separator, so this is the key with its first letter raised — `adCtrScatter`
// reads as `AdCtrScatter`, exactly as the story's dropdown does.
String _optionText(String key) => key
    .split(RegExp(r'[-_]'))
    .map(
      (String word) =>
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');

// `JSON.stringify(schema, null, 2)`. Written out because this page may import
// only fluent_2_web, flutter/widgets and the catalog, and so has no JSON
// encoder to call.
String _stringify(Object? value, [String indent = '']) {
  final String inner = '$indent  ';
  if (value is Map<String, Object?>) {
    if (value.isEmpty) {
      return '{}';
    }
    return '{\n'
        '${value.entries.map((MapEntry<String, Object?> entry) => '$inner"${entry.key}": ${_stringify(entry.value, inner)}').join(',\n')}'
        '\n$indent}';
  }
  if (value is List<Object?>) {
    if (value.isEmpty) {
      return '[]';
    }
    return '[\n'
        '${value.map((Object? item) => '$inner${_stringify(item, inner)}').join(',\n')}'
        '\n$indent]';
  }
  if (value is String) {
    return '"$value"';
  }
  return '$value';
}

// Upstream's ErrorBoundary: red text in a 1px red box, 4px radius, 20px inset.
Widget _errorBoundary(BuildContext context, String message) {
  const Color red = Color(0xFFFF0000);
  final FluentTypography type = FluentTheme.of(context).typography;
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: red),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Error rendering chart:',
          style: type.subtitle2.copyWith(color: red),
        ),
        const SizedBox(height: 8),
        Text(message, style: type.body1.copyWith(color: red)),
      ],
    ),
  );
}

// Two of upstream's controls need a runtime this page does not have, and are
// adapted rather than faked:
//
//  * The JSON pane is read-only. Upstream re-parses the textarea on every
//    keystroke and prints a "JSON Parse Error:" line beneath it when the text
//    stops being valid JSON; with no decoder to import there is nothing to
//    parse, so the pane shows the selected schema and the chart is driven by
//    the Dart map beside it.
//  * "Show more" fetches a hundred schemas at a time from the
//    fluentui-charting-contrib repository, keeps
//    `results.filter((item) => item !== null) as Array<…>` of them, and then
//    prints an "Additional GitHub Examples:" count beside a "Load more"
//    button. The showroom ships no network client, so the switch does the one
//    thing left to it — widen the Category list from `All` alone to every
//    category the twenty-five inline schemas fall into.
class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  final TextEditingController _schemaText = TextEditingController();
  final TextEditingController _widthText = TextEditingController(text: '600');
  final TextEditingController _heightText = TextEditingController(text: '400');

  String _selectedChart = _allSchemas.keys.first;
  String _selectedCategory = 'All';
  bool _showMore = false;
  int _width = 600;
  int _height = 400;

  @override
  void initState() {
    super.initState();
    _selectChart(_selectedChart);
  }

  @override
  void dispose() {
    _schemaText.dispose();
    _widthText.dispose();
    _heightText.dispose();
    super.dispose();
  }

  void _selectChart(String key) {
    _selectedChart = key;
    _schemaText.text = _stringify(_allSchemas[key]!);
  }

  // `{...parsedSchema, width, height}` at the render site: the two inputs are
  // written into the spec as well as sizing the box around it.
  Map<String, Object?> get _spec => <String, Object?>{
    ..._allSchemas[_selectedChart]!,
    'width': _width,
    'height': _height,
  };

  // In "show few" mode the Category dropdown offers `All` alone.
  List<String> get _categories => _showMore
      ? <String>['All', ..._schemaCategories.keys]
      : const <String>['All'];

  int _categoryCount(String category) {
    if (category == 'All') {
      return _allSchemas.length;
    }
    return _showMore ? _schemaCategories[category]!.length : 0;
  }

  void _onShowMoreChanged(bool value) => setState(() {
    _showMore = value;
    if (!value) {
      _selectedCategory = 'All';
      _selectChart(_allSchemas.keys.first);
    }
  });

  void _onSizeChanged(String text, {required bool isWidth}) {
    final int? value = int.tryParse(text);
    if (value == null || value <= 0) {
      return;
    }
    setState(() {
      if (isWidth) {
        _width = value;
      } else {
        _height = value;
      }
    });
  }

  Widget _sizeField(
    String label,
    TextEditingController controller, {
    required bool isWidth,
  }) => FluentField(
    label: Text(label),
    child: SizedBox(
      width: 100,
      child: FluentInput(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (String text) => _onSizeChanged(text, isWidth: isWidth),
      ),
    ),
  );

  Widget _bullet(FluentTypography type, String label, String text) => Text.rich(
    TextSpan(
      children: <InlineSpan>[
        TextSpan(text: '• $label ', style: type.body1Strong),
        TextSpan(text: text, style: type.body1),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final FluentTypography type = FluentTheme.of(context).typography;
    final int schemaCount = _allSchemas.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Vega-Lite Declarative Chart - $schemaCount Schemas',
          style: type.title1,
        ),
        const SizedBox(height: 12),
        Text(
          _showMore
              ? 'This component renders charts from Vega-Lite specifications. '
                    'Browse through $schemaCount chart examples (including '
                    'additional schemas from GitHub). Use "Load more" to load '
                    'additional schemas from the fluentui-charting-contrib '
                    'repository.'
              : 'This component renders charts from Vega-Lite specifications. '
                    'Browse through $schemaCount chart examples. Enable "Show '
                    'more" to load thousands of additional examples from '
                    'GitHub.',
          style: type.body1,
        ),
        const SizedBox(height: 20),
        FluentSwitch(
          checked: _showMore,
          onChanged: _onShowMoreChanged,
          label: Text(_showMore ? 'Show more' : 'Show few'),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: <Widget>[
            FluentField(
              label: const Text('Category'),
              // The 150px and 300px widths sit on the controls rather than on
              // the fields: a fixed field would clip its own label.
              child: SizedBox(
                width: 150,
                child: FluentDropdown<String>(
                  options: <FluentDropdownOption<String>>[
                    for (final String category in _categories)
                      FluentDropdownOption<String>(
                        value: category,
                        label: Text('$category (${_categoryCount(category)})'),
                      ),
                  ],
                  value: _selectedCategory,
                  // Upstream reads the selection and then never filters on it —
                  // `const filteredOptions = currentOptions` — so the Chart
                  // Type list stays whole here too.
                  onChanged: (String value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
            ),
            FluentField(
              label: const Text('Chart Type'),
              child: SizedBox(
                width: 300,
                child: FluentDropdown<String>(
                  options: <FluentDropdownOption<String>>[
                    for (final String key in _allSchemas.keys)
                      FluentDropdownOption<String>(
                        value: key,
                        label: Text(_optionText(key)),
                      ),
                  ],
                  value: _selectedChart,
                  onChanged: (String value) =>
                      setState(() => _selectChart(value)),
                ),
              ),
            ),
            _sizeField('Width (px)', _widthText, isWidth: true),
            _sizeField('Height (px)', _heightText, isWidth: false),
          ],
        ),
        const SizedBox(height: 20),
        // `gridTemplateColumns: '1fr 1fr'`.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: <Widget>[
            Expanded(
              child: FluentField(
                label: const Text('Vega-Lite Schema (JSON)'),
                child: FluentTextarea(
                  controller: _schemaText,
                  readOnly: true,
                  minLines: 20,
                  maxLines: 20,
                ),
              ),
            ),
            Expanded(
              child: FluentField(
                label: const Text('Chart Preview'),
                // The declared width outruns half the page long before 600px,
                // so the preview scrolls sideways rather than overflowing it.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _width.toDouble(),
                    height: _height.toDouble(),
                    child: FluentVegaDeclarativeChart(
                      // Upstream keys the chart on the same three values, so
                      // any of them changing remounts it.
                      key: ValueKey<String>('$_selectedChart-$_width-$_height'),
                      chartSchema: FluentVegaSchema(vegaLiteSpec: _spec),
                      errorBuilder: _errorBoundary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Chart Categories ($schemaCount Total):', style: type.subtitle2),
        const SizedBox(height: 8),
        // `columns: 2` on the list.
        Wrap(
          spacing: 24,
          runSpacing: 4,
          children: <Widget>[
            for (final MapEntry<String, List<String>> entry
                in _schemaCategories.entries)
              SizedBox(
                width: 260,
                child: _bullet(
                  type,
                  '${entry.key}:',
                  '${entry.value.length} charts',
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Features Supported:', style: type.subtitle2),
        const SizedBox(height: 8),
        for (final (String label, String text) in _features)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _bullet(type, label, text),
          ),
      ],
    );
  }
}

// #enddocregion charts-vegadeclarativechart--default
