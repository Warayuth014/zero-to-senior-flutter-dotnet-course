import 'package:flutter/material.dart';

import 'pallet.dart';
import 'pallet_store.dart';

/// จอพาเลทหลังแยกชั้น — ไฟล์นี้ทำงานเดียวคือ "วาดสิ่งที่ store บอก และส่ง
/// สิ่งที่ผู้ใช้ทำกลับไปให้ store"
///
/// ไม่มี http ไม่มี jsonDecode ไม่มีการแปลรหัสตอบกลับ ไม่มี setState แม้แต่ที่
/// เดียว เพราะไม่มีสถานะเป็นของตัวเองให้เก็บ (9.10)
class PalletScreenV2 extends StatefulWidget {
  const PalletScreenV2({super.key, required this.store, required this.zone});

  final PalletStore store;
  final String zone;

  @override
  State<PalletScreenV2> createState() => _PalletScreenV2State();
}

class _PalletScreenV2State extends State<PalletScreenV2> {
  @override
  void initState() {
    super.initState();
    widget.store.load(widget.zone);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('พาเลทในโซน ${widget.zone}'),
      actions: [
        IconButton(
          key: const Key('reload-button'),
          tooltip: 'โหลดใหม่',
          onPressed: widget.store.refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        if (store.initialLoading) {
          return const Center(
            key: Key('initial-loading'),
            child: CircularProgressIndicator(),
          );
        }
        if (store.failure case final failure? when store.pallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.message, key: const Key('error-text')),
                // canRetry มาจาก repository ไม่ใช่จากการเดาเลข status ในจอ
                if (failure.canRetry)
                  FilledButton(
                    key: const Key('retry-button'),
                    onPressed: store.refresh,
                    child: const Text('ลองใหม่'),
                  ),
              ],
            ),
          );
        }
        if (store.pallets.isEmpty) {
          return const Center(
            key: Key('empty-text'),
            child: Text('ไม่มีพาเลทในโซนนี้'),
          );
        }
        return Column(
          children: [
            if (store.failure case final failure?)
              Text(failure.message, key: const Key('banner-error-text')),
            Expanded(
              child: ListView.builder(
                itemCount: store.pallets.length,
                itemBuilder: (context, index) {
                  final pallet = store.pallets[index];
                  return _PalletTile(
                    key: Key('pallet-${pallet.code}'),
                    pallet: pallet,
                    busy: store.isBusy(pallet.code),
                    onHold: () => store.hold(pallet),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PalletTile extends StatelessWidget {
  const _PalletTile({
    super.key,
    required this.pallet,
    required this.busy,
    required this.onHold,
  });

  final Pallet pallet;
  final bool busy;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(pallet.code),
    subtitle: Text('${pallet.productCode} x${pallet.quantity}'),
    trailing: pallet.onHold
        ? const Text('ล็อกแล้ว')
        : FilledButton(
            key: Key('hold-${pallet.code}'),
            onPressed: busy ? null : onHold,
            child: const Text('ล็อก'),
          ),
  );
}
