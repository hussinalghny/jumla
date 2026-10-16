// JUMLA — Data models · Developed by GHANI CODE (ghanicode.com) · © All rights reserved

double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String _s(dynamic v) => v == null ? '' : '$v';
String? _sn(dynamic v) => v == null || '$v'.isEmpty ? null : '$v';
Map<String, dynamic> _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<dynamic> _l(dynamic v) => v is List ? v : const [];

class Money {
  const Money(this.usd, this.iqd);
  factory Money.fromJson(dynamic j) {
    final m = _m(j);
    return Money(_d(m['usd']), _i(m['iqd']));
  }
  final double usd;
  final int iqd;
  static const zero = Money(0, 0);
  Money times(num n) => Money(usd * n, ((iqd * n) / 250).round() * 250);
}

class ProductCategory {
  ProductCategory.fromJson(dynamic j)
      : id = _i(_m(j)['id']),
        slug = _s(_m(j)['slug']),
        name = _s(_m(j)['name']),
        icon = _s(_m(j)['icon']),
        count = _i(_m(j)['products_count']);
  final int id;
  final String slug, name, icon;
  final int count;
}

class SizeQty {
  SizeQty(this.size, this.qty);
  final String size;
  final int qty;
}

class Supplier {
  Supplier.fromJson(dynamic j)
      : name = _s(_m(j)['name']),
        city = _s(_m(j)['city']),
        years = _i(_m(j)['years']),
        rating = _i(_m(j)['rating']);
  final String name, city;
  final int years, rating;
}

class Product {
  Product.fromJson(dynamic json) : this._(_m(json));
  Product._(Map<String, dynamic> j)
      : id = _i(j['id']),
        name = _s(j['name']),
        price = Money.fromJson(j['price']),
        packQty = _i(j['pack_qty']) < 1 ? 1 : _i(j['pack_qty']),
        packPrice = Money.fromJson(j['pack_price']),
        sizes = _l(j['sizes']).map((s) => SizeQty(_s(_m(s)['size']), _i(_m(s)['qty']))).toList(),
        freeSize = j['free_size'] == true,
        sizesText = _s(j['sizes_text']),
        colors = _s(j['colors']),
        categoryName = _s(_m(j['category'])['name']),
        categorySlug = _s(_m(j['category'])['slug']),
        image = _sn(j['image']),
        imagesCount = _i(j['images_count']),
        rating = _d(j['rating']),
        sold = _i(j['sold']),
        featured = j['featured'] == true,
        description = _s(j['description']),
        images = _l(j['images']).map((e) => '$e').toList(),
        leadDays = _i(j['lead_days']),
        supplier = j['supplier'] is Map ? Supplier.fromJson(j['supplier']) : null,
        landedPerPiece = j['landed_estimate'] is Map ? Money.fromJson(_m(j['landed_estimate'])['per_piece']) : null,
        landedMethod = _sn(_m(j['landed_estimate'])['ship_method']),
        related = _l(j['related']).map((e) => Product.fromJson(e)).toList();

  final int id;
  final String name;
  final Money price;
  final int packQty;
  final Money packPrice;
  final List<SizeQty> sizes;
  final bool freeSize;
  final String sizesText, colors, categoryName, categorySlug;
  final String? image;
  final int imagesCount;
  final double rating;
  final int sold;
  final bool featured;
  // تفاصيل (تتوفر في صفحة المنتج)
  final String description;
  final List<String> images;
  final int leadDays;
  final Supplier? supplier;
  final Money? landedPerPiece;
  final String? landedMethod;
  final List<Product> related;

  String get sizesShort => freeSize || sizes.isEmpty ? 'فري سايز' : sizes.map((s) => s.size).join('/');
  List<String> get gallery => images.isNotEmpty ? images : [if (image != null) image!];
}

class ShipMethod {
  ShipMethod.fromJson(dynamic j)
      : key = _s(_m(j)['key']),
        name = _s(_m(j)['name']),
        icon = _s(_m(j)['icon']),
        days = _s(_m(j)['days']);
  final String key, name, icon, days;
}

class PayMethod {
  PayMethod.fromJson(dynamic j)
      : key = _s(_m(j)['key']),
        name = _s(_m(j)['name']),
        icon = _s(_m(j)['icon']),
        description = _s(_m(j)['description']),
        instructions = _s(_m(j)['instructions']);
  final String key, name, icon, description, instructions;
}

class SiteInfo {
  SiteInfo.fromJson(dynamic j)
      : name = _s(_m(j)['name']),
        nameAr = _s(_m(j)['name_ar']),
        tagline = _s(_m(j)['tagline']),
        phone = _s(_m(j)['phone']),
        whatsapp = _sn(_m(j)['whatsapp']),
        email = _s(_m(j)['email']),
        instagram = _s(_m(j)['instagram']),
        address = _s(_m(j)['address']);
  final String name, nameAr, tagline, phone, email, instagram, address;
  final String? whatsapp;
}

class ConfigData {
  ConfigData.fromJson(dynamic json) : this._(_m(json));
  ConfigData._(Map<String, dynamic> j)
      : site = SiteInfo.fromJson(j['site']),
        rate = _d(_m(j['currency'])['usd_iqd']),
        customsPercent = _d(_m(j['fees'])['customs_percent']),
        servicePercent = _d(_m(j['fees'])['service_percent']),
        depositPercent = _d(_m(j['fees'])['deposit_percent']),
        shipMethods = _l(j['ship_methods']).map((e) => ShipMethod.fromJson(e)).toList(),
        payMethods = _l(j['pay_methods']).map((e) => PayMethod.fromJson(e)).toList(),
        governorates = _l(j['governorates']).map((e) => '$e').toList();
  final SiteInfo site;
  final double rate, customsPercent, servicePercent, depositPercent;
  final List<ShipMethod> shipMethods;
  final List<PayMethod> payMethods;
  final List<String> governorates;

  ShipMethod? ship(String key) {
    for (final s in shipMethods) {
      if (s.key == key) return s;
    }
    return null;
  }
}

class Totals {
  Totals.fromJson(dynamic json) : this._(_m(json));
  Totals._(Map<String, dynamic> j)
      : itemsQty = _i(j['items_qty']),
        weightKg = _d(j['weight_kg']),
        cbm = _d(j['cbm']),
        subtotal = Money.fromJson(j['subtotal']),
        shipping = Money.fromJson(j['shipping']),
        customs = Money.fromJson(j['customs']),
        fee = Money.fromJson(j['fee']),
        total = Money.fromJson(j['total']);
  final int itemsQty;
  final double weightKg, cbm;
  final Money subtotal, shipping, customs, fee, total;
}

class QuoteItem {
  QuoteItem.fromJson(dynamic j)
      : product = Product.fromJson(_m(j)['product']),
        qty = _i(_m(j)['qty']),
        packs = _i(_m(j)['packs']),
        line = Money.fromJson(_m(j)['line_total']);
  final Product product;
  final int qty, packs;
  final Money line;
}

class Quote {
  Quote.fromJson(dynamic json) : this._(_m(json));
  Quote._(Map<String, dynamic> j)
      : items = _l(j['items']).map((e) => QuoteItem.fromJson(e)).toList(),
        shipMethod = _s(j['ship_method']),
        totals = Totals.fromJson(j['totals']),
        byMethod = _m(j['totals_by_method']).map((k, v) => MapEntry(k, Money.fromJson(v))),
        cheapest = _sn(j['cheapest_method']),
        unavailable = _l(j['unavailable']).map(_i).toList();
  final List<QuoteItem> items;
  final String shipMethod;
  final Totals totals;
  final Map<String, Money> byMethod;
  final String? cheapest;
  final List<int> unavailable;
}

class OrderItem {
  OrderItem.fromJson(dynamic j)
      : productId = _m(j)['product_id'] == null ? null : _i(_m(j)['product_id']),
        name = _s(_m(j)['name']),
        image = _sn(_m(j)['image']),
        unitPrice = Money.fromJson(_m(j)['unit_price']),
        qty = _i(_m(j)['qty']),
        packs = _i(_m(j)['packs']),
        sizes = _s(_m(j)['sizes']),
        line = Money.fromJson(_m(j)['line_total']);
  final int? productId;
  final String name;
  final String? image;
  final Money unitPrice;
  final int qty, packs;
  final String sizes;
  final Money line;
}

class TimelineStep {
  TimelineStep.fromJson(dynamic j)
      : stage = _i(_m(j)['stage']),
        name = _s(_m(j)['name']),
        description = _s(_m(j)['description']),
        state = _s(_m(j)['state']),
        date = _sn(_m(j)['date']);
  final int stage;
  final String name, description, state;
  final String? date;
}

class Order {
  Order.fromJson(dynamic json) : this._(_m(json));
  Order._(Map<String, dynamic> j)
      : code = _s(j['code']),
        createdAt = _s(j['created_at']),
        stage = _i(_m(j['status'])['stage']),
        statusName = _s(_m(j['status'])['name']),
        cancelled = _m(j['status'])['cancelled'] == true,
        delivered = _m(j['status'])['delivered'] == true,
        shipKey = _s(_m(j['ship_method'])['key']),
        shipName = _s(_m(j['ship_method'])['name']),
        shipIcon = _s(_m(j['ship_method'])['icon']),
        shipDays = _s(_m(j['ship_method'])['days']),
        payKey = _s(_m(j['pay_method'])['key']),
        payName = _s(_m(j['pay_method'])['name']),
        payIcon = _s(_m(j['pay_method'])['icon']),
        total = Money.fromJson(j['total']),
        paid = Money.fromJson(j['paid']),
        remaining = Money.fromJson(j['remaining']),
        itemsQty = _i(j['items_qty']),
        image = _sn(j['image']),
        totals = j['totals'] is Map ? _m(j['totals']).map((k, v) => MapEntry(k, Money.fromJson(v))) : const {},
        deliveryName = _s(_m(j['delivery'])['name']),
        deliveryPhone = _s(_m(j['delivery'])['phone']),
        deliveryCity = _s(_m(j['delivery'])['city']),
        deliveryAddress = _s(_m(j['delivery'])['address']),
        notes = _s(j['notes']),
        paymentInstructions = _s(j['payment_instructions']),
        depositDue = j['deposit_due'] is Map ? Money.fromJson(j['deposit_due']) : null,
        items = _l(j['items']).map((e) => OrderItem.fromJson(e)).toList(),
        timeline = _l(j['timeline']).map((e) => TimelineStep.fromJson(e)).toList();

  final String code, createdAt;
  final int stage;
  final String statusName;
  final bool cancelled, delivered;
  final String shipKey, shipName, shipIcon, shipDays, payKey, payName, payIcon;
  final Money total, paid, remaining;
  final int itemsQty;
  final String? image;
  final Map<String, Money> totals;
  final String deliveryName, deliveryPhone, deliveryCity, deliveryAddress, notes, paymentInstructions;
  final Money? depositDue;
  final List<OrderItem> items;
  final List<TimelineStep> timeline;

  bool get isActive => !cancelled && !delivered;
  String? get firstImage => image ?? (items.isNotEmpty ? items.first.image : null);
  int get piecesCount => itemsQty > 0 ? itemsQty : items.fold(0, (a, b) => a + b.qty);
}

class Customer {
  Customer.fromJson(dynamic json) : this._(_m(json));
  Customer._(Map<String, dynamic> j)
      : id = _i(j['id']),
        name = _s(j['name']),
        shopName = _s(j['shop_name']),
        phone = _s(j['phone']),
        city = _s(j['city']),
        address = _s(j['address']),
        wallet = Money.fromJson(j['wallet']),
        ordersCount = _i(_m(j['stats'])['orders']),
        activeOrders = _i(_m(j['stats'])['active_orders']),
        totalSpent = Money.fromJson(_m(j['stats'])['total_spent']);
  final int id;
  final String name, shopName, phone, city, address;
  final Money wallet;
  final int ordersCount, activeOrders;
  final Money totalSpent;

  String get displayName => shopName.isNotEmpty ? shopName : name;
}

class Rfq {
  Rfq.fromJson(dynamic json) : this._(_m(json));
  Rfq._(Map<String, dynamic> j)
      : id = _i(j['id']),
        productName = _s(j['product_name']),
        category = _s(j['category']),
        qty = _i(j['qty']),
        targetPrice = j['target_price'] == null ? null : _d(j['target_price']),
        specs = _s(j['specs']),
        status = _s(j['status']),
        statusName = _s(j['status_name']),
        reply = _sn(j['reply']),
        createdAt = _s(j['created_at']);
  final int id;
  final String productName, category;
  final int qty;
  final double? targetPrice;
  final String specs, status, statusName;
  final String? reply;
  final String createdAt;
}
