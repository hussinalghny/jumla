// JUMLA — Product card · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../screens/product_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'jicon.dart';
import 'ui.dart';

/// ارتفاع منطقة النص أسفل صورة البطاقة
const double kCardTextHeight = 104;

double cardExtent(double width) => width * 1.25 + kCardTextHeight;

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.heroPrefix});
  final Product product;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = product;
    final tag = '$heroPrefix-${p.id}';
    return Pressable(
      onTap: () => Navigator.of(context).push(slideRoute(ProductScreen(id: p.id, preview: p, heroTag: tag))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(fit: StackFit.expand, children: [
              Hero(tag: tag, child: NetImage(p.image)),
              if (p.featured)
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xD9FFFFFF), borderRadius: BorderRadius.circular(20)),
                    child: Text('الأكثر طلباً', style: ts(10.5, w: FontWeight.w600)),
                  ),
                ),
              if (p.imagesCount > 1)
                PositionedDirectional(
                  bottom: 8,
                  end: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(20)),
                    child: Text('${p.imagesCount} ألوان', style: ts(10.5, c: Colors.white)),
                  ),
                ),
            ]),
          ),
          SizedBox(
            height: kCardTextHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(13.5, w: FontWeight.w600, h: 1.35)),
                const Spacer(),
                Row(children: [
                  Flexible(child: AnimatedText(s.money(p.price), style: ts(17, w: FontWeight.w700))),
                  Text(' / قطعة', style: ts(11, c: C.muted)),
                ]),
                const SizedBox(height: 2),
                Text('سيري ${p.packQty} قطع · ${p.sizesShort}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11.5, c: C.muted)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// شبكة منتجات (Sliver) بعمودين
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, required this.heroPrefix});
  final List<Product> products;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 32 - 12) / 2;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: cardExtent(w),
        ),
        delegate: SliverChildBuilderDelegate(
          (c, i) => FadeIn(index: i % 6, child: ProductCard(product: products[i], heroPrefix: heroPrefix)),
          childCount: products.length,
        ),
      ),
    );
  }
}

/// شبكة تحميل مؤقتة
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 32 - 12) / 2;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: cardExtent(w)),
        delegate: SliverChildBuilderDelegate(
          (c, i) => Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(aspectRatio: 4 / 5, child: Skeleton(radius: 0, height: double.infinity, width: double.infinity)),
              const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 6), child: Skeleton(height: 12)),
              const Padding(padding: EdgeInsets.fromLTRB(12, 0, 60, 6), child: Skeleton(height: 12)),
              const Padding(padding: EdgeInsets.fromLTRB(12, 6, 80, 0), child: Skeleton(height: 16)),
            ]),
          ),
          childCount: count,
        ),
      ),
    );
  }
}

/// أيقونة القسم
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});
  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: JIcon(category.icon, size: 28),
          ),
          const SizedBox(height: 8),
          Text(category.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: ts(12, w: FontWeight.w500, h: 1.3)),
        ]),
      ),
    );
  }
}
