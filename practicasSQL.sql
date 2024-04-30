/*
Punto 1
Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.
*/

SELECT clie_codigo, clie_razon_social
FROM Cliente
WHERE clie_limite_credito >= 1000;

/*
Punto 2
Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.
*/

SELECT prod_codigo, prod_detalle
FROM Producto
         JOIN Item_Factura ON prod_codigo = item_producto
         JOIN Factura ON fact_numero = item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad) desc


/*
Punto 3
Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.
 */

SELECT prod_codigo, prod_detalle, ISNULL(SUM(stoc_cantidad),0) AS stock
FROM Producto
    LEFT JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle

/*
Punto 4
Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.
 */

SELECT prod_codigo, prod_detalle, COUNT(DISTINCT comp_componente) AS componentes
FROM Producto
    LEFT JOIN Composicion ON prod_codigo = comp_producto
    JOIN STOCK ON stoc_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle
HAVING AVG(stoc_cantidad) > 100
ORDER BY COUNT(comp_componente) desc

/*
Punto 5
Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.
*/

SELECT prod_codigo, prod_detalle, SUM(item_cantidad) AS cantidad
FROM Producto
         JOIN Item_Factura ON prod_codigo = item_producto
         JOIN Factura ON fact_numero = item_numero
WHERE YEAR(fact_fecha) = 2012
group by prod_codigo, prod_detalle
HAVING SUM(item_cantidad) > (select sum(item_cantidad)
                             FROM Item_Factura
                                      JOIN Factura ON fact_numero = item_numero
                             WHERE YEAR(fact_fecha) = 2011
                               AND item_producto = prod_codigo)

/*
Punto 6
Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.
*/


