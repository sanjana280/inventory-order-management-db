USE inventory_order_management_db;

DROP VIEW IF EXISTS v_current_inventory;
DROP VIEW IF EXISTS v_order_details;
DROP VIEW IF EXISTS v_monthly_sales_summary;
DROP VIEW IF EXISTS v_supplier_purchase_summary;
DROP VIEW IF EXISTS v_low_stock_alert;

CREATE VIEW v_current_inventory AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    s.supplier_name,
    w.warehouse_name,
    w.location,
    i.quantity,
    p.reorder_level,
    CASE
        WHEN i.quantity <= 0 THEN 'OUT OF STOCK'
        WHEN i.quantity <= p.reorder_level THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END AS stock_status
FROM inventory i
JOIN products p ON i.product_id = p.product_id
LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
JOIN warehouses w ON i.warehouse_id = w.warehouse_id;

CREATE VIEW v_order_details AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    c.customer_name,
    c.phone AS customer_phone,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.subtotal,
    o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;

CREATE VIEW v_monthly_sales_summary AS
SELECT
    YEAR(order_date) AS sales_year,
    MONTH(order_date) AS sales_month,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS total_sales
FROM orders
WHERE status IN ('SHIPPED', 'DELIVERED')
GROUP BY YEAR(order_date), MONTH(order_date);

CREATE VIEW v_supplier_purchase_summary AS
SELECT
    s.supplier_name,
    COUNT(po.purchase_order_id) AS total_purchase_orders,
    SUM(po.total_amount) AS total_purchase_amount
FROM suppliers s
LEFT JOIN purchase_orders po ON s.supplier_id = po.supplier_id
GROUP BY s.supplier_id, s.supplier_name;
CREATE VIEW v_low_stock_alert AS
SELECT
    product_id,
    sku,
    product_name,
    category,
    supplier_name,
    warehouse_name,
    location,
    quantity,
    reorder_level,
    stock_status
FROM v_current_inventory
WHERE stock_status IN ('LOW STOCK', 'OUT OF STOCK');
