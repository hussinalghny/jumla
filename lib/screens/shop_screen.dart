// JUMLA — Shop (search, filter, infinite scroll) · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.standalone = false, this.category, this.categoryName, this.autofocusSearch = false});
  final bool standalone;
  final String? category, categoryName;
  final bool autofocusSearch;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _sorts = {'popular': 'الأكثر مبيعاً', 'new': 'الأحدث', 'price_asc': 'السعر: الأقل', 'price_desc': 'السعر: الأعلى', 'pack': 'أصغر سيري', 'rating': 'الأعلى تقييماً'};

  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<ProductCategory> _cats = [];
  final List<Product> _items = [];
  String? _cat;
  String _sort = 'popular';
  int _page = 1, _pages = 1, _total = 0, _req = 0;
  bool _loading = true, _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cat = widget.category;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _more();
    });
    _loadCats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    if (widget.autofocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Future.delayed(Motion.slow, () {
            if (mounted) _focus.requestFocus();
          }));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCats() async {
    try {
      final r = await Api.i.get('/categories');
      if (mounted) setState(() => _cats = (r.data as List).map((e) => ProductCategory.fromJson(e)).toList());
    } catch (_) {}
  }

  Map<String, String> get _query => {
        'page': '$_page',
        'per_page': '20',
        'sort': _sort,
        if (_cat != null) 'category': _cat!,
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
      };

  Future<void> _reload() async {
    final my = ++_req;
    setState(() {
      _page = 1;
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.i.get('/products', query: _query);
      if (!mounted || my != _req) return;
      setState(() {
        _items
          ..clear()
          ..addAll((r.data as List).map((e) => Product.fromJson(e)));
        _pages = r.pages;
        _total = r.total;
        _loading = false;
      });
    } catch (e) {
      if (mounted && my == _req) setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _more() async {
    if (_loading || _loadingMore || _page >= _pages) return;
    final my = _req;
    setState(() => _loadingMore = true);
    _page++;
    try {
      final r = await Api.i.get('/products', query: _query);
      if (!mounted || my != _req) return;
      setState(() {
        _items.addAll((r.data as List).map((e) => Product.fromJson(e)));
        _loadingMore = false;
      });
    } catch (_) {
      _page--;
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  Future<void> _pickSort() async {
    final label = await pickFrom(context, 'ترتيب حسب', _sorts.values.toList(), selected: _sorts[_sort]);
    if (label == null) return;
    final key = _sorts.entries.firstWhere((e) => e.value == label).key;
    if (key != _sort) {
      _sort = key;
      _reload();
    }
  }

  String get _title {
    if (_cat == null) return 'المتجر';
    for (final c in _cats) {
      if (c.slug == _cat) return c.name;
    }
    return widget.categoryName ?? 'المتجر';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LargeTitlePage(
          title: _title,
          controller: _scroll,
          onRefresh: _reload,
          trailing: Pressable(
            onTap: _pickSort,
            scale: .9,
            child: const Padding(padding: EdgeInsets.all(6), child: JIcon('sort', size: 22, color: C.accent)),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: CupertinoSearchTextField(
                  controller: _search,
                  focusNode: _focus,
                  placeholder: 'ابحث عن موديل أو لون...',
                  style: ts(16),
                  placeholderStyle: ts(16, c: C.muted),
                  onChanged: _onSearch,
                  onSubmitted: (_) => _reload(),
                  onSuffixTap: () {
                    _search.clear();
                    _reload();
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    _Chip(label: 'الكل', active: _cat == null, onTap: () {
                      if (_cat != null) {
                        setState(() => _cat = null);
                        _reload();
                      }
                    }),
                    for (final c in _cats)
                      _Chip(label: c.name, icon: c.icon, active: _cat == c.slug, onTap: () {
                        if (_cat != c.slug) {
                          setState(() => _cat = c.slug);
                          _reload();
                        }
                      }),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: AnimatedText(_loading ? ' ' : '$_total منتج · ${_sorts[_sort]}', style: ts(13, c: C.muted)),
              ),
            ),
            if (_loading)
              const ProductGridSkeleton(count: 6)
            else if (_error != null)
              SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: _reload))
            else if (_items.isEmpty)
              const SliverToBoxAdapter(child: EmptyState(icon: 'search', title: 'ما لقينا منتجات', sub: 'جرّب كلمة بحث ثانية أو قسم آخر.'))
            else
              ProductGrid(products: _items, heroPrefix: 'shop${widget.standalone ? '-s' : ''}'),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: Motion.fast,
                child: _loadingMore ? const Padding(padding: EdgeInsets.all(20), child: CupertinoActivityIndicator()) : const SizedBox(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap, this.icon});
  final String label;
  final String? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: active ? C.text : Colors.white, borderRadius: BorderRadius.circular(999)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[JIcon(icon!, size: 16, color: active ? Colors.white : C.muted), const SizedBox(width: 6)],
            Text(label, style: ts(13.5, w: FontWeight.w500, c: active ? Colors.white : C.text)),
          ]),
        ),
      ),
    );
  }
}
