import 'package:flutter/material.dart';

import '../../data/models/service.dart';
import '../../widgets/molecules/section_header.dart';

class ServicesList extends StatelessWidget {
  const ServicesList({super.key, required this.services, required this.onSelect});

  final List<ServiceModel> services;
  final void Function(ServiceModel) onSelect;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Bu işletme için hizmet bulunamadı.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Hizmetler'),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final service = services[index];
            return ListTile(
              title: Text(service.name),
              subtitle: Text(service.description ?? ''),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${service.price.toStringAsFixed(0)} ₺'),
                  Text('${service.durationMinutes} dk'),
                ],
              ),
              onTap: () => onSelect(service),
            );
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: services.length,
        ),
      ],
    );
  }
}
