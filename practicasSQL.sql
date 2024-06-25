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
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) cantidad
FROM Producto
         JOIN Item_Factura ON prod_codigo = item_producto
         JOIN Factura ON fact_numero = item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad) desc;

/*
Punto 3
Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.
 */
SELECT prod_codigo, prod_detalle, ISNULL(SUM(stoc_cantidad), 0) AS stock
FROM Producto
         LEFT JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle;

/*
Punto 4
Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.
*/

SELECT prod_codigo, prod_detalle, Count(DISTINCT comp_componente) AS componentes
FROM Producto
         LEFT JOIN Composicion ON prod_codigo = comp_producto
         JOIN STOCK ON stoc_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle
HAVING AVG(stoc_cantidad) > 100
ORDER BY COUNT(comp_componente) desc;

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
                               AND item_producto = prod_codigo);

/*
Punto 6
Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/

select rubr_id,
       rubr_detalle,
       COUNT(distinct prod_codigo) as cantidad_por_rubro,
       SUM(stoc_cantidad)          as stock_total,
       rubr_detalle
from Rubro
         left join Producto on prod_rubro = rubr_id
         join STOCK on prod_codigo = stoc_producto
where prod_codigo in
      (select stoc_producto
       from STOCK
       group by stoc_producto
       having SUM(stoc_cantidad) > (select stoc_cantidad
                                    from STOCK
                                    where stoc_producto = '00000000'
                                      and stoc_deposito = '00'))
group by rubr_id, rubr_detalle;

/*.
Punto 7
Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.
*/


select prod_codigo,
       prod_detalle,
       MIN(item_precio)                                                                          as precio_minimo,
       MAX(item_precio)                                                                          as precio_maximo,
       CAST((((MAX(item_precio) - MIN(item_precio)) / MIN(item_precio)) * 100) as decimal(8, 2)) as porcentaje_diferencia
from Item_Factura
         join Producto on item_producto = prod_codigo
         join STOCK on prod_codigo = stoc_producto
group by prod_codigo, prod_detalle
having SUM(stoc_cantidad) > 0
order by porcentaje_diferencia DESC;

/*
Punto 8
Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.
*/

select prod_detalle, MAX(stoc_cantidad)
from Producto
         join STOCK on stoc_producto = prod_codigo
group by prod_codigo, prod_detalle
having COUNT() = (select COUNT() from DEPOSITO);

/*
Punto 9
Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.
*/

SELECT empl_jefe, empl_codigo, empl_nombre, empl_apellido, COUNT(depo_codigo)
FROM Empleado
         JOIN DEPOSITO ON empl_codigo = depo_encargado
    OR empl_jefe = depo_encargado
GROUP BY empl_jefe, empl_codigo, empl_nombre, empl_apellido

/*
Punto 10
Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo.
*/

SELECT prod_detalle,
       SUM(item_cantidad) as cantidad,
       (SELECT TOP 1 clie_razon_social
        FROM Cliente
                 JOIN Factura F ON Cliente.clie_codigo = F.fact_cliente
                 JOIN Item_Factura I ON F.fact_tipo = I.item_tipo AND F.fact_sucursal = I.item_sucursal AND
                                        F.fact_numero = I.item_numero AND I.item_producto = prod_codigo
        ORDER BY item_cantidad DESC) as 'Mejor cliente'
FROM Producto
         JOIN Item_Factura on Producto.prod_codigo = item_producto
WHERE prod_codigo IN (SELECT TOP 10 prod_codigo
                      FROM Producto
                               JOIN Item_Factura ON prod_codigo = item_producto
                      GROUP BY prod_codigo
                      ORDER BY SUM(item_cantidad) DESC)
   OR prod_codigo IN (SELECT TOP 10 prod_codigo
                      FROM Producto
                               JOIN Item_Factura ON prod_codigo = item_producto
                      GROUP BY prod_codigo
                      ORDER BY SUM(item_cantidad))
GROUP BY prod_detalle, prod_codigo
ORDER BY SUM(item_cantidad) DESC




/*
Punto 11
Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.
*/

SELECT DISTINCT fami_detalle, COUNT(DISTINCT prod_codigo) as 'cant_prod_familia', SUM(DISTINCT fact_total) as "total_s_imp"
FROM Familia
         JOIN dbo.Producto P on Familia.fami_id = P.prod_familia
         JOIN dbo.Item_Factura I on P.prod_codigo = I.item_producto
         JOIN dbo.Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY fami_detalle
HAVING SUM(fact_total) >= 20000
ORDER BY cant_prod_familia DESC


/*
Punto 12
Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.
*/

SELECT prod_detalle,
       prod_codigo,
       (SELECT COUNT(distinct fact_cliente)
        FROM Factura
                 JOIN Item_Factura F
                      on fact_tipo = item_tipo and fact_sucursal = item_sucursal and
                         fact_numero = item_numero and item_producto = prod_codigo)            as cant_clie,
       AVG(item_precio)                                                                        as precio_prom,
       (SELECT COUNT(DISTINCT stoc_deposito)
        FROM STOCK
        WHERE prod_codigo = stoc_producto)                                                     as cant_depos_con_stock,
       (SELECT SUM(DISTINCT stoc_cantidad) FROM STOCK WHERE prod_codigo = STOCK.stoc_producto) as stock,
       SUM(item_precio)
FROM Producto
         JOIN Item_Factura I on Producto.prod_codigo = I.item_producto
WHERE prod_codigo IN (SELECT prod_codigo
                      FROM Producto
                               JOIN Item_Factura ON prod_codigo = item_producto
                               JOIN dbo.Factura F2 on F2.fact_tipo = Item_Factura.item_tipo and
                                                      F2.fact_sucursal = Item_Factura.item_sucursal and
                                                      F2.fact_numero = Item_Factura.item_numero
                      WHERE YEAR(F2.fact_fecha) = 2012)
GROUP BY prod_detalle, prod_codigo
ORDER BY SUM(item_precio) DESC

/*
Punto 13
Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.
*/

SELECT prod_detalle,
       prod_codigo,
       prod_precio                   as precio_unitario,
       (prod_precio * comp_cantidad) as precio_total,
       (SELECT COUNT(comp_producto) FROM Composicion WHERE comp_producto = C.comp_producto)
FROM Producto
         JOIN dbo.Composicion C on Producto.prod_codigo = C.comp_componente
GROUP BY prod_codigo, prod_detalle, prod_precio, (prod_precio * comp_cantidad), comp_producto
HAVING  (SELECT COUNT(comp_producto) FROM Composicion WHERE comp_producto = C.comp_producto) > 2
ORDER BY (SELECT COUNT(comp_producto) FROM Composicion WHERE comp_producto = C.comp_producto) DESC

/*
Punto 14
Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
debe retornar son:
Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna
*/

SELECT clie_codigo,
       COUNT(clie_codigo)                           as cant_compras,
       AVG(fact_total)                              as prom_compra,
       COUNT(DISTINCT item_producto)                as cant_prod,
       ISNULL((SELECT MAX(fact_total)
               FROM Factura
               WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = clie_codigo), 0) as mayor_comp
FROM Cliente
         JOIN Factura F on Cliente.clie_codigo = F.fact_cliente
         JOIN Item_Factura I
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
GROUP BY clie_codigo, fact_fecha, fact_cliente
ORDER BY (SELECT COUNT(DISTINCT item_producto)
          FROM Item_Factura
                   JOIN Factura on Item_Factura.item_tipo = Factura.fact_tipo and
                                   Item_Factura.item_sucursal = Factura.fact_sucursal and
                                   Item_Factura.item_numero = Factura.fact_numero and
                                   Factura.fact_cliente = Cliente.clie_codigo
          WHERE YEAR(Factura.fact_fecha) = 2012)

/*
Punto 15
Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
*/

SELECT Item1.item_producto AS prod1,
       Prod1.prod_detalle  AS detalle1,
       Item2.item_producto AS prod2,
       Prod2.prod_detalle  AS detalle2,
       COUNT(*)            AS veces_vendidos_juntos
FROM Item_Factura Item1
         JOIN Item_Factura Item2 ON Item1.item_numero = Item2.item_numero AND Item1.item_producto < Item2.item_producto
         JOIN Producto Prod1 ON Item1.item_producto = Prod1.prod_codigo
         JOIN Producto Prod2 ON Item2.item_producto = Prod2.prod_codigo
    GROUP BY Item1.item_producto, Prod1.prod_detalle, Item2.item_producto, Prod2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY COUNT(*)

/*
Punto 16
Con el fin de lanzar una nueva campaña comercial para los clientes que menos compranen la empresa,
se pide una consulta SQL que retorne aquellos clientes cuyas ventas son inferiores a 1/3 del promedio de ventas
del producto que más se vendió en el 2012.

Además mostrar:
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente.
*/

SELECT clie_codigo,
       clie_razon_social,
       SUM(item_cantidad)       as cant_unidades,
       (SELECT TOP 1 prod_detalle
        FROM Producto
                 JOIN Item_Factura ON item_producto = Producto.prod_codigo
                 JOIN Factura ON fact_numero = item_numero AND fact_cliente = Cliente.clie_codigo
        ORDER BY item_cantidad DESC) AS prod_mas_comprado
FROM Cliente
         JOIN Factura F on Cliente.clie_codigo = F.fact_cliente
         JOIN dbo.Item_Factura I
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
GROUP BY clie_codigo, clie_razon_social, clie_domicilio
HAVING SUM(fact_total) < (SELECT AVG(fact_total) FROM Factura WHERE YEAR(fact_fecha) = 2012) / 3
ORDER BY clie_domicilio

/*
Punto 17
Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.

La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.
*/

SELECT FORMAT(fact_fecha, 'yyyy-MM')                                   as PERIODO,
       prod_codigo,
       prod_detalle,
       sum(item_cantidad)                                              as CANTIDAD_VENDIDA,
       ISNULL((SELECT sum(item_cantidad)
               FROM Item_Factura I2
                        JOIN dbo.Factura F2 on F2.fact_tipo = I2.item_tipo and F2.fact_sucursal = I2.item_sucursal and
                                               F2.fact_numero = I2.item_numero
               WHERE I2.item_producto = I.item_producto
                 AND MONTH(F2.fact_fecha) = MONTH(F.fact_fecha)
                 AND year(F2.fact_fecha) = YEAR(F.fact_fecha) - 1), 0) as VENTAS_AÑO_ANT,
       COUNT(fact_numero + F.fact_sucursal + fact_tipo)                as CANT_FACTURAS
FROM Producto
         JOIN dbo.Item_Factura I on Producto.prod_codigo = I.item_producto
         JOIN dbo.Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
GROUP BY prod_codigo, prod_detalle, FORMAT(fact_fecha, 'yyyy-MM'), item_producto, MONTH(fact_fecha), YEAR(fact_fecha)

/*
Punto 18
Escriba una consulta que retorne una estadística de ventas para todos los rubros.

La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.
*/

SELECT rubr_detalle                                               as DETALLE_RUBRO,
       CAST((sum(item_precio * item_cantidad)) AS decimal(12, 2)) as VENTAS,
       ISNULL((SELECT TOP 1 prod_codigo
               FROM Producto
                        JOIN Item_Factura ON Producto.prod_codigo = item_producto
               WHERE prod_rubro = P.prod_rubro
               GROUP BY prod_codigo, prod_rubro
               ORDER BY SUM(item_cantidad) DESC), '-')            as PROD1,
       ISNULL((SELECT TOP 1 prod_codigo
               FROM Producto
                        JOIN dbo.Item_Factura IF2 ON Producto.prod_codigo = IF2.item_producto
               WHERE prod_rubro = P.prod_rubro
                 AND prod_codigo NOT IN (SELECT TOP 1 prod_codigo
                                         FROM Producto
                                                  JOIN Item_Factura ON Producto.prod_codigo = item_producto
                                         WHERE prod_rubro = P.prod_rubro
                                         GROUP BY prod_codigo, prod_rubro
                                         ORDER BY SUM(item_cantidad) DESC)
               GROUP BY prod_codigo
               ORDER BY SUM(item_cantidad) DESC),
              '-')                                                as PROD2,
       ISNULL((SELECT TOP 1 fact_cliente
               FROM Factura
                        JOIN dbo.Item_Factura I
                             on Factura.fact_tipo = I.item_tipo and Factura.fact_sucursal = I.item_sucursal and
                                Factura.fact_numero = I.item_numero
                        JOIN dbo.Producto on prod_codigo = I.item_producto
               WHERE prod_rubro = P.prod_rubro
                 AND fact_fecha BETWEEN DATEADD(DAY, -30, (SELECT MAX(fact_fecha) FROM Factura)) AND (SELECT MAX(fact_fecha) FROM Factura)
               GROUP BY fact_cliente
               ORDER BY sum(item_cantidad) DESC), '-')            as CLIENTE
FROM Rubro
         JOIN dbo.Producto P
              on Rubro.rubr_id = P.prod_rubro
         JOIN dbo.Item_Factura I on P.prod_codigo = I.item_producto
         JOIN dbo.Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
GROUP BY rubr_detalle, prod_rubro
ORDER BY COUNT(DISTINCT item_producto)

/*
Punto 19.
En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:

     Codigo de producto
     Detalle del producto
     Codigo de la familia del producto
     Detalle de la familia actual del producto
     Codigo de la familia sugerido para el producto
     Detalla de la familia sugerido para el producto

La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.

En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida

Los resultados deben ser ordenados por detalle de producto de manera ascendente
*/

SELECT prod_codigo,
       prod_detalle,
       fami_id,
       fami_detalle,
       (SELECT TOP 1 fami_id
        FROM Producto
                 JOIN Familia ON fami_id = prod_familia
        WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(P1.prod_detalle, 1, 5)
        GROUP BY fami_id
        ORDER BY COUNT(*) DESC) as cod_fam_sug,
       (SELECT TOP 1 fami_detalle
        FROM Producto
                 JOIN Familia ON fami_id = prod_familia
        WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(P1.prod_detalle, 1, 5)
        GROUP BY fami_detalle
        ORDER BY COUNT(*) DESC) as det_fam_sug
FROM Producto P1
         JOIN dbo.Familia F on F.fami_id = P1.prod_familia
WHERE fami_id <> (SELECT TOP 1 fami_id
                  FROM Producto
                           JOIN Familia ON fami_id = prod_familia
                  WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(P1.prod_detalle, 1, 5)
                  GROUP BY fami_id
                  ORDER BY COUNT(*) DESC)
GROUP BY prod_codigo, prod_detalle, fami_id, fami_detalle
ORDER BY prod_detalle

/*
Punto 20.
Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012

Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012.

El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año,
para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año.

*/

SELECT TOP 3 empl_codigo                                           as Legajo,
             CONCAT(RTRIM(empl_nombre), ' ', RTRIM(empl_apellido)) as Nombre_y_apellido,
             CAST(empl_ingreso AS DATE)                            AS Ingreso,
             (SELECT CASE
                         WHEN COUNT(*) >= 50 THEN (SELECT COUNT(*)
                                                   FROM Factura
                                                   WHERE fact_vendedor = Empleado.empl_codigo
                                                     AND YEAR(fact_fecha) = 2011
                                                     AND fact_total > 100)
                         ELSE (SELECT COUNT(*) * 0.5
                               FROM Factura
                                        JOIN dbo.Empleado E on E.empl_codigo = Factura.fact_vendedor
                               WHERE empl_jefe = Empleado.empl_codigo
                                 AND YEAR(fact_fecha) = 2011) END
              FROM Factura
              WHERE YEAR(fact_fecha) = 2011
                AND fact_vendedor = Empleado.empl_codigo)          AS Puntaje_2011,
             (SELECT CASE
                         WHEN COUNT(*) >= 50 THEN (SELECT COUNT(*)
                                                   FROM Factura
                                                   WHERE fact_vendedor = Empleado.empl_codigo
                                                     AND YEAR(fact_fecha) = 2012
                                                     AND fact_total > 100)
                         ELSE (SELECT COUNT(*) * 0.5
                               FROM Factura
                                        JOIN dbo.Empleado E on E.empl_codigo = Factura.fact_vendedor
                               WHERE empl_jefe = Empleado.empl_codigo
                                 AND YEAR(fact_fecha) = 2012) END
              FROM Factura
              WHERE YEAR(fact_fecha) = 2011
                AND fact_vendedor = Empleado.empl_codigo)          AS Puntaje_2012
FROM Empleado
GROUP BY empl_codigo, empl_nombre, empl_apellido, empl_ingreso
ORDER BY (SELECT CASE
                     WHEN COUNT(*) >= 50 THEN (SELECT COUNT(*)
                                               FROM Factura
                                               WHERE fact_vendedor = Empleado.empl_codigo
                                                 AND YEAR(fact_fecha) = 2012
                                                 AND fact_total > 100)
                     ELSE (SELECT COUNT(*) * 0.5
                           FROM Factura
                                    JOIN dbo.Empleado E on E.empl_codigo = Factura.fact_vendedor
                           WHERE empl_jefe = Empleado.empl_codigo
                             AND YEAR(fact_fecha) = 2012) END
          FROM Factura
          WHERE YEAR(fact_fecha) = 2011
            AND fact_vendedor = Empleado.empl_codigo) DESC


/*
Punto 21.
Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta.

Se considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
 Año
 Clientes a los que se les facturo mal en ese año
 Facturas mal realizadas en ese año
*/

SELECT YEAR(fact_fecha)                                        AS Año,
       COUNT(DISTINCT fact_cliente)                            AS Cant_clientes_afectados,
       COUNT(DISTINCT fact_numero + fact_sucursal + fact_tipo) AS Facturas_incorrectas
FROM Factura
WHERE ABS(((fact_total - fact_total_impuestos) -
      (SELECT SUM(item_cantidad * item_precio)
       FROM Item_Factura
       WHERE item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo) )) > 1
GROUP BY YEAR(fact_fecha)

/*
Punto 22.
Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años.
Se mostraran como maximo 4 filas por rubro (1 por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre

El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.
*/

SELECT rubr_detalle,
       DATEPART(QUARTER, fact_fecha)                             AS Trimestre,
       COUNT(DISTINCT fact_tipo + F.fact_numero + fact_sucursal) AS Fact_x_trim,
       COUNT(DISTINCT item_producto)                             AS Prod_x_trim
FROM Rubro
         JOIN Producto P on Rubro.rubr_id = P.prod_rubro
         JOIN Item_Factura I on P.prod_codigo = I.item_producto
         JOIN Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
WHERE prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
GROUP BY rubr_detalle, DATEPART(QUARTER, fact_fecha)
HAVING COUNT(DISTINCT fact_tipo + F.fact_numero + fact_sucursal) > 100
ORDER BY 1, 3 DESC


/*
Punto 23.
Realizar una consulta SQL que para cada año muestre :
 Año
 El producto con composición más vendido para ese año.
 Cantidad de productos que componen directamente al producto más vendido
 La cantidad de facturas en las cuales aparece ese producto.
 El código de cliente que más compro ese producto.
 El porcentaje que representa la venta de ese producto respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente.
*/

SELECT YEAR(fact_fecha)                               as Año,
       prod_codigo,
       prod_detalle,
       COUNT(DISTINCT comp_componente)                AS cant_comp,
       COUNT(DISTINCT item_numero)                    AS cant_fact,
       (SELECT TOP 1 fact_cliente
        FROM Factura
                 JOIN dbo.Item_Factura IF2
                      on Factura.fact_tipo = IF2.item_tipo and Factura.fact_sucursal = IF2.item_sucursal and
                         Factura.fact_numero = IF2.item_numero
        WHERE IF2.item_producto = I.item_producto
          AND YEAR(F1.fact_fecha) = YEAR(fact_fecha)
        GROUP BY fact_cliente
        ORDER BY SUM(item_cantidad) DESC)             AS mejor_cli,
       (SELECT (SELECT SUM(item_cantidad)
                FROM Factura
                         JOIN dbo.Item_Factura IF3
                              on Factura.fact_tipo = IF3.item_tipo and Factura.fact_sucursal = IF3.item_sucursal and
                                 Factura.fact_numero = IF3.item_numero
                WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)
                  AND item_producto = I.item_producto) / SUM(item_cantidad) * 100
        FROM Factura
                 JOIN dbo.Item_Factura IF3
                      on Factura.fact_tipo = IF3.item_tipo and Factura.fact_sucursal = IF3.item_sucursal and
                         Factura.fact_numero = IF3.item_numero
        WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)) AS porcentaje_del_año
FROM Factura F1
         JOIN dbo.Item_Factura I on F1.fact_tipo = I.item_tipo and F1.fact_sucursal = I.item_sucursal and
                                    F1.fact_numero = I.item_numero
         JOIN dbo.Producto P on P.prod_codigo = I.item_producto
         JOIN dbo.Composicion C on P.prod_codigo = C.comp_producto
WHERE item_producto IN (SELECT TOP 1 item_producto
                        FROM Item_Factura
                                 JOIN dbo.Factura F on F.fact_tipo = Item_Factura.item_tipo and
                                                       F.fact_sucursal = Item_Factura.item_sucursal and
                                                       F.fact_numero = Item_Factura.item_numero
                                 JOIN Composicion ON item_producto = comp_producto
                        GROUP BY item_producto
                        ORDER BY COUNT(item_producto) DESC)
GROUP BY YEAR(fact_fecha), prod_codigo, prod_detalle, item_producto
ORDER BY 5 DESC


/*
Punto 24.
Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
 Código de Producto
 Nombre del Producto
 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente.
*/

SELECT prod_codigo,
       prod_detalle,
       SUM(item_cantidad)
FROM Producto
         JOIN Item_Factura ON prod_codigo = item_producto
         JOIN dbo.Factura F on F.fact_tipo = Item_Factura.item_tipo and F.fact_sucursal = Item_Factura.item_sucursal and
                               F.fact_numero = Item_Factura.item_numero
WHERE F.fact_vendedor IN (SELECT TOP 2 empl_codigo FROM Empleado ORDER BY empl_comision DESC)
  AND prod_codigo IN (SELECT comp_producto FROM Composicion)
    GROUP BY prod_codigo, prod_detalle
HAVING COUNT(fact_numero) > 5


/*
Punto 25.
Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente.
*/

SELECT YEAR(fact_fecha)                               AS año,
       prod_familia,
       COUNT(DISTINCT prod_rubro)                     AS cant_rubros,
       CASE
           WHEN (SELECT TOP 1 prod_codigo
                 FROM Producto P1
                          JOIN dbo.Item_Factura I on P1.prod_codigo = I.item_producto
                          JOIN dbo.Factura on fact_tipo = I.item_tipo and fact_sucursal = I.item_sucursal and
                                              fact_numero = I.item_numero
                 WHERE prod_familia = P.prod_familia
                   AND YEAR(fact_fecha) = YEAR(Factura.fact_fecha)
                 GROUP BY prod_codigo
                 ORDER BY SUM(item_cantidad) DESC) IN
                (SELECT comp_producto FROM Composicion)
               THEN (SELECT COUNT(comp_producto)
                     FROM Composicion
                     WHERE comp_producto = (SELECT TOP 1 prod_codigo
                                            FROM Producto P1
                                                     JOIN dbo.Item_Factura I on P1.prod_codigo = I.item_producto
                                                     JOIN dbo.Factura on fact_tipo = I.item_tipo and
                                                                         fact_sucursal = I.item_sucursal and
                                                                         fact_numero = I.item_numero
                                            WHERE prod_familia = P.prod_familia
                                              AND YEAR(fact_fecha) = YEAR(F1.fact_fecha)
                                            GROUP BY prod_codigo
                                            ORDER BY SUM(item_cantidad) DESC))
           ELSE 1 END                                 AS cant_prod_comp,
       COUNT(DISTINCT fact_numero)                    AS cant_facturas,
       (SELECT TOP 1 fact_cliente
        FROM Factura
                 JOIN dbo.Item_Factura IF2
                      on Factura.fact_tipo = IF2.item_tipo and Factura.fact_sucursal = IF2.item_sucursal and
                         Factura.fact_numero = IF2.item_numero
                 JOIN dbo.Producto P2 on P2.prod_codigo = IF2.item_producto
        WHERE prod_familia = P.prod_familia
          AND YEAR(fact_fecha) = YEAR(F1.fact_fecha)
        GROUP BY fact_cliente
        ORDER BY SUM(item_cantidad) DESC)             AS mejor_cli,
       (SELECT (SELECT SUM(item_cantidad)
                FROM Factura
                         JOIN dbo.Item_Factura IF3
                              on Factura.fact_tipo = IF3.item_tipo and Factura.fact_sucursal = IF3.item_sucursal and
                                 Factura.fact_numero = IF3.item_numero
                         JOIN dbo.Producto P3 on P3.prod_codigo = IF3.item_producto
                WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)
                  AND P.prod_familia = P3.prod_familia) / SUM(item_cantidad) * 100
        FROM Factura
                 JOIN dbo.Item_Factura IF3
                      on Factura.fact_tipo = IF3.item_tipo and Factura.fact_sucursal = IF3.item_sucursal and
                         Factura.fact_numero = IF3.item_numero
        WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)) AS porcentaje_del_año
FROM Factura F1
         JOIN dbo.Item_Factura I on F1.fact_tipo = I.item_tipo and F1.fact_sucursal = I.item_sucursal and
                                    F1.fact_numero = I.item_numero
         JOIN dbo.Producto P on P.prod_codigo = I.item_producto
WHERE prod_familia = (SELECT TOP 1 prod_familia
                      FROM Producto
                               JOIN dbo.Item_Factura I on Producto.prod_codigo = I.item_producto
                               JOIN dbo.Factura F
                                    on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and
                                       F.fact_numero = I.item_numero
                      GROUP BY prod_familia
                      ORDER BY SUM(item_cantidad) DESC)
GROUP BY YEAR(fact_fecha), prod_familia
ORDER BY 5 DESC, 2 DESC


/*
Punto 26.
Escriba una consulta sql que retorne un ranking de empleados devolviendo las siguientes columnas:
 Empleado
 Depósitos que tiene a cargo
 Monto total facturado en el año corriente
 Codigo de Cliente al que mas le vendió
 Producto más vendido
 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.
*/

SELECT empl_codigo,
       COUNT(DISTINCT depo_codigo)                                                             AS depos_a_cargo,
       ISNULL((SELECT SUM(fact_total) FROM Factura F1 WHERE fact_vendedor = E.empl_codigo), 0) AS monto_fact,
       ISNULL((SELECT TOP 1 fact_cliente
               FROM Factura F2
               WHERE fact_vendedor = E.empl_codigo
               GROUP BY fact_cliente
               ORDER BY COUNT(fact_cliente)), '-')                                             AS mejor_cli,
       ISNULL((SELECT TOP 1 item_producto
               FROM Item_Factura
                        JOIN dbo.Factura F3 on F3.fact_tipo = Item_Factura.item_tipo and
                                               F3.fact_sucursal = Item_Factura.item_sucursal and
                                               F3.fact_numero = Item_Factura.item_numero and
                                               F3.fact_vendedor = E.empl_codigo
               GROUP BY item_producto
               ORDER BY SUM(item_cantidad) DESC), '-')                                         AS prod_mas_vendido,
       ISNULL((SELECT (SELECT SUM(item_cantidad)
                       FROM Factura
                                JOIN dbo.Item_Factura IF3
                                     on Factura.fact_tipo = IF3.item_tipo and
                                        Factura.fact_sucursal = IF3.item_sucursal and
                                        Factura.fact_numero = IF3.item_numero
                       WHERE fact_vendedor = E.empl_codigo) / SUM(item_cantidad) * 100
               FROM Factura
                        JOIN dbo.Item_Factura IF3
                             on Factura.fact_tipo = IF3.item_tipo and Factura.fact_sucursal = IF3.item_sucursal and
                                Factura.fact_numero = IF3.item_numero), 0)                     AS porcentaje_del_año
FROM Empleado E
         LEFT OUTER JOIN dbo.DEPOSITO D on E.empl_codigo = D.depo_encargado
         LEFT JOIN Factura F ON E.empl_codigo = F.fact_vendedor
GROUP BY empl_codigo

/*
Punto 27.
Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:

 Año
 Codigo de envase
 Detalle del envase
 Cantidad de productos que tienen ese envase
 Cantidad de productos facturados de ese envase
 Producto mas vendido de ese envase
 Monto total de venta de ese envase en ese año
 Porcentaje de la venta de ese envase respecto al total vendido de ese año

Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor
*/

SELECT YEAR(fact_fecha)                                                                           AS año,
       prod_envase,
       enva_detalle,
       COUNT(DISTINCT item_producto)                                                              AS cant_prod_envase,
       SUM(item_cantidad)                                                                         AS cant_env_facturados,
       (SELECT TOP 1 prod_codigo
        FROM Producto
                 JOIN dbo.Item_Factura IF1 on Producto.prod_codigo = IF1.item_producto
                 JOIN dbo.Factura F2 on F2.fact_tipo = IF1.item_tipo and F2.fact_sucursal = IF1.item_sucursal and
                                        F2.fact_numero = IF1.item_numero
        WHERE prod_envase = P.prod_envase
          AND YEAR(F2.fact_fecha) = YEAR(F.fact_fecha)
        GROUP BY prod_codigo
        ORDER BY SUM(item_cantidad) DESC)                                                         AS prod_mas_vend,
       SUM(item_precio * I.item_cantidad)                                                         AS monto_total,
       (SUM(item_cantidad * I.item_precio) / (SELECT SUM(fact_total)
                                              FROM Factura
                                              WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)) * 100) AS porcentaje
FROM Factura F
         JOIN dbo.Item_Factura I on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and
                                    F.fact_numero = I.item_numero
         JOIN dbo.Producto P on P.prod_codigo = I.item_producto
         JOIN dbo.Envases E on P.prod_envase = E.enva_codigo
GROUP BY YEAR(fact_fecha), prod_envase, enva_detalle
ORDER BY 1, 5 DESC



/*
Punto 28.
Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
 Año.
 Codigo de Vendedor
 Detalle del Vendedor
 Cantidad de facturas que realizó en ese año
 Cantidad de clientes a los cuales les vendió en ese año.
 Cantidad de productos facturados con composición en ese año
 Cantidad de productos facturados sin composicion en ese año.
 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.
*/

SELECT YEAR(fact_fecha)                                                     AS año,
       CONCAT(RTRIM(empl_nombre), ' ', RTRIM(empl_apellido))                as nombre_y_apellido,
       COUNT(fact_numero)                                                   AS cant_fact,
       COUNT(DISTINCT fact_cliente)                                         AS cant_cli,
       (SELECT COUNT(DISTINCT item_producto)
        FROM Item_Factura
                 JOIN dbo.Factura F2
                      on F2.fact_tipo = Item_Factura.item_tipo and F2.fact_sucursal = Item_Factura.item_sucursal and
                         F2.fact_numero = Item_Factura.item_numero and F2.fact_vendedor = E.empl_codigo
                 JOIN Composicion on item_producto = comp_producto
        WHERE YEAR(F2.fact_fecha) = YEAR(F.fact_fecha))                     AS cant_prod_comp,
       (SELECT COUNT(DISTINCT item_producto)
        FROM Item_Factura
                 JOIN dbo.Factura F2
                      on F2.fact_tipo = Item_Factura.item_tipo and F2.fact_sucursal = Item_Factura.item_sucursal and
                         F2.fact_numero = Item_Factura.item_numero and F2.fact_vendedor = E.empl_codigo
        WHERE YEAR(F2.fact_fecha) = YEAR(F.fact_fecha)
          AND item_producto NOT IN (SELECT comp_producto FROM Composicion)) AS cant_prod_simples,
       SUM(fact_total)                                                      AS monto_total
FROM Factura F
         JOIN Empleado E on E.empl_codigo = F.fact_vendedor
GROUP BY YEAR(fact_fecha), CONCAT(RTRIM(empl_nombre), ' ', RTRIM(empl_apellido)), empl_codigo
ORDER BY 1 DESC,
         (SELECT COUNT(DISTINCT item_producto)
          FROM Item_Factura
                   JOIN dbo.Factura F3
                        on F3.fact_tipo = Item_Factura.item_tipo and F3.fact_sucursal = Item_Factura.item_sucursal and
                           F3.fact_numero = Item_Factura.item_numero and F3.fact_vendedor = E.empl_codigo
          WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)) DESC

/*
Punto 29.
Se solicita que realice una estadística de venta por producto para el año 2011, solo para
los productos que pertenezcan a las familias que tengan más de 20 productos asignados
a ellas, la cual deberá devolver las siguientes columnas:
a. Código de producto
b. Descripción del producto
c. Cantidad vendida
d. Cantidad de facturas en la que esta ese producto
e. Monto total facturado de ese producto
Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.
*/

SELECT prod_codigo,
       prod_detalle,
       SUM(item_cantidad)               AS cant_vendida,
       COUNT(item_cantidad)             AS cant_fact,
       SUM(item_cantidad * item_precio) AS monto
FROM Producto P
         JOIN Item_Factura ON item_producto = P.prod_codigo
WHERE (SELECT COUNT(DISTINCT prod_codigo) FROM Producto WHERE prod_familia = P.prod_familia) > 20
GROUP BY prod_codigo, prod_detalle
ORDER BY 3 DESC


/*
Punto 30.
Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:
 Nombre del Jefe
 Cantidad de empleados a cargo
 Monto total vendido de los empleados a cargo
 Cantidad de facturas realizadas por los empleados a cargo
 Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.
*/

SELECT CONCAT(RTRIM(E.empl_nombre), ' ', RTRIM(E.empl_apellido)) AS nombre_y_apellido,
       COUNT(DISTINCT E2.empl_codigo)                            AS empl_a_cargo,
       SUM(F.fact_total)                                         AS monto_total,
       COUNT(fact_vendedor)                                      AS cant_fact,
       (SELECT TOP 1 CONCAT(RTRIM(empl_nombre), ' ', RTRIM(empl_apellido))
        FROM Empleado
                 JOIN dbo.Factura F2 on Empleado.empl_codigo = F2.fact_vendedor
        WHERE empl_jefe = E.empl_codigo
        GROUP BY empl_nombre, empl_apellido
        ORDER BY SUM(F2.fact_total) DESC)                        AS mejor_empl
FROM Empleado E
         JOIN Empleado E2 ON E2.empl_jefe = E.empl_codigo
         JOIN dbo.Factura F on E2.empl_codigo = F.fact_vendedor
GROUP BY E.empl_codigo, E.empl_nombre, E.empl_apellido
ORDER BY 3 DESC


/*
Punto 31.
Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
 Año.
 Codigo de Vendedor
 Detalle del Vendedor
 Cantidad de facturas que realizó en ese año
 Cantidad de clientes a los cuales les vendió en ese año.
 Cantidad de productos facturados con composición en ese año
 Cantidad de productos facturados sin composicion en ese año.
 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.


IGUAL AL 28
*/

/*
Punto 32.
Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
siguientes columnas:
 Código de familia
 Detalle de familia
 Código de familia
 Detalle de familia
 Cantidad de facturas
 Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas más de 10 veces.
*/

SELECT F1.fami_id,
       F1.fami_detalle,
       F2.fami_id,
       F2.fami_detalle,
       COUNT(DISTINCT IF1.item_numero + IF1.item_sucursal + IF1.item_tipo)            AS cant_fact,
       SUM(IF1.item_cantidad * IF1.item_precio + IF2.item_cantidad * IF1.item_precio) AS total
FROM Item_Factura IF1
         JOIN Item_Factura IF2 ON IF1.item_numero = IF2.item_numero AND IF1.item_tipo = IF2.item_tipo AND
                                  IF1.item_sucursal = IF2.item_sucursal AND
                                  IF1.item_producto < IF2.item_producto
         JOIN Producto P1 on P1.prod_codigo = IF1.item_producto
         JOIN Familia F1 on F1.fami_id = P1.prod_familia
         JOIN Producto P2 ON P2.prod_codigo = IF2.item_producto
         JOIN Familia F2 on F2.fami_id = P2.prod_familia
WHERE F1.fami_id < F2.fami_id
GROUP BY F1.fami_id, F1.fami_detalle, F2.fami_id, F2.fami_detalle
HAVING COUNT(DISTINCT IF1.item_numero + IF1.item_sucursal + IF1.item_tipo) > 10
ORDER BY 6 DESC


/*
Punto 33.
Se requiere obtener una estadística de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto más vendido del año 2012. Se deberá mostrar:
a. Código de producto
b. Nombre del producto
c. Cantidad de unidades vendidas
d. Cantidad de facturas en la cual se facturo
e. Precio promedio facturado de ese producto.
f. Total facturado para ese producto
El resultado deberá ser ordenado por el total vendido por producto para el año 2012.
*/

SELECT prod_codigo,
       prod_detalle,
       SUM(item_cantidad) * comp_cantidad AS cant_unidades,
       COUNT(DISTINCT fact_numero+F.fact_sucursal+fact_tipo) AS cant_fact,
       AVG(item_precio*item_cantidad) AS precio_prom,
       SUM(item_precio*I.item_cantidad) AS total_fact
FROM Producto
         JOIN dbo.Composicion C on Producto.prod_codigo = C.comp_componente
         JOIN dbo.Item_Factura I on comp_producto = I.item_producto
         JOIN dbo.Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
WHERE comp_producto = (SELECT TOP 1 comp_producto
                       FROM Composicion
                                JOIN Item_Factura ON item_producto = comp_producto
                                JOIN dbo.Factura F2 on F2.fact_tipo = Item_Factura.item_tipo and
                                                       F2.fact_sucursal = Item_Factura.item_sucursal and
                                                       F2.fact_numero = Item_Factura.item_numero and
                                                       YEAR(F2.fact_fecha) = 2012
                       GROUP BY comp_producto
                       ORDER BY SUM(item_cantidad) DESC)
GROUP BY prod_codigo, prod_detalle, comp_cantidad

/*
Punto 34.
Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal
facturadas por cada mes del año 2011.
Se considera que una factura es incorrecta cuando en la misma factura se factutan productos
de dos rubros diferentes. Si no hay facturas mal hechas se debe retornar 0.

Las columnas que se deben mostrar son:
1- Codigo de Rubro
2- Mes
3- Cantidad de facturas mal realizadas.
*/

SELECT prod_rubro,
       MONTH(fact_fecha) AS mes,
       COUNT(DISTINCT F.fact_tipo+F.fact_sucursal+F.fact_numero) AS facturas_incorrectas
FROM Producto
         JOIN Item_Factura I on Producto.prod_codigo = I.item_producto
         JOIN Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
WHERE YEAR(fact_fecha) = 2011
GROUP BY prod_rubro, MONTH(fact_fecha)


/*
Punto 35.
Se requiere realizar una estadística de ventas por año y producto, para ello se solicita
que escriba una consulta sql que retorne las siguientes columnas:
 Año
 Codigo de producto
 Detalle del producto
 Cantidad de facturas emitidas a ese producto ese año
 Cantidad de vendedores diferentes que compraron ese producto ese año.
 Cantidad de productos a los cuales compone ese producto, si no compone a ninguno
se debera retornar 0.
 Porcentaje de la venta de ese producto respecto a la venta total de ese año.
Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida.
*/

SELECT YEAR(fact_fecha)                                                                              AS año,
       prod_codigo,
       prod_detalle,
       COUNT(DISTINCT fact_numero + fact_tipo + fact_sucursal)                                       AS cant_facturas,
       COUNT(DISTINCT fact_vendedor)                                                                 AS cant_vendedores,
       ISNULL((SELECT COUNT(comp_producto) FROM Composicion WHERE comp_componente = prod_codigo), 0) AS cant_prod_comp,
       SUM(item_cantidad * item_precio) * 100 /
       (SELECT SUM(fact_total) FROM Factura WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha))             AS promedio
FROM Producto
         JOIN dbo.Item_Factura I on Producto.prod_codigo = I.item_producto
         JOIN dbo.Factura F
              on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero
GROUP BY YEAR(fact_fecha), prod_codigo, prod_detalle
ORDER BY 1, SUM(item_cantidad) DESC


------------------------------ TRANSACT SQL ------------------------------

/*
Punto 1.
Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/

CREATE FUNCTION dbo.EstadoDeposito (@deposito char(2), @producto char(8))
RETURNS char(30)
AS
    BEGIN
        DECLARE @ocupacion decimal(12,2) =
            (SELECT (stoc_cantidad * 100 / stoc_stock_maximo)
             FROM STOCK
             WHERE stoc_deposito = @deposito
               AND stoc_producto = @producto)
        RETURN
            CASE
                WHEN @ocupacion = 100
                    THEN ('DEPOSITO COMPLETO')
                ELSE ('OCUPACION DEL DEPOSITO ' + CONVERT(varchar(10),@ocupacion) +
                      '%')
                END
    END
GO


/*
Punto 2.
Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/

CREATE FUNCTION dbo.StockEnFecha(@producto CHAR(8), @fecha DATETIME)
    RETURNS DECIMAL(12, 2)
AS
BEGIN
    RETURN (SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = @producto) + (SELECT SUM(item_cantidad)
                                                                                     FROM Item_Factura
                                                                                              JOIN dbo.Factura F
                                                                                                   on F.fact_tipo =
                                                                                                      Item_Factura.item_tipo and
                                                                                                      F.fact_sucursal =
                                                                                                      Item_Factura.item_sucursal and
                                                                                                      F.fact_numero =
                                                                                                      Item_Factura.item_numero
                                                                                     WHERE item_producto = @producto AND fact_fecha >= @fecha);

END


/*
Punto 3.
Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario.
Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe).
Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el gerente general,
el cual será seleccionado por mayor salario. Si hay más de uno se seleccionara
el de mayor antigüedad en la empresa. Al finalizar la ejecución del objeto la
tabla deberá cumplir con la regla de un único empleado sin jefe (el gerente general)
y deberá retornar la cantidad de empleados que había sin jefe antes de la ejecución.
*/


CREATE PROC ChequearGerentes (@CantSinJefe int OUTPUT)
AS
    BEGIN
        DECLARE @GerenteGrl numeric(6) = (SELECT TOP 1 empl_codigo
                                          FROM Empleado
                                          WHERE empl_jefe IS NULL
                                          ORDER BY empl_salario DESC, empl_ingreso)
        SET @CantSinJefe  = (SELECT count(*) FROM Empleado WHERE empl_jefe IS NULL)

        IF @CantSinJefe > 1
            UPDATE Empleado SET empl_jefe = @GerenteGrl WHERE empl_jefe IS NULL AND Empleado.empl_codigo <> @GerenteGrl
        ELSE
            PRINT 'hay 1 solo'

    END
    GO

INSERT Empleado
VALUES (99,'juan','pedro','1978-01-01 00:00:00','2020-01-03 00:00:00','Gerente',20000,0.5,NULL,1)

SELECT * FROM Empleado WHERE empl_jefe IS NULL AND empl_codigo <> 1
UPDATE Empleado SET empl_jefe = NULL WHERE empl_codigo = 99
DELETE Empleado WHERE empl_codigo = 99

DECLARE @Modiff int
EXEC ChequearGerentes @Modiff OUTPUT
PRINT @Modiff

/*
Punto 4.
Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.
*/

IF OBJECT_ID('EmplEj4','U') IS NOT NULL
DROP TABLE EmplEj4
GO
SELECT * INTO EmplEj4 FROM Empleado

GO
CREATE PROC ActualizarComisiones (@vendedor DECIMAL(12,2) OUTPUT)
    AS
    BEGIN
        UPDATE EmplEj4
        SET empl_comision = (SELECT SUM(fact_total)
                             FROM Factura
                             WHERE YEAR(fact_fecha) =
                                   (SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY YEAR(fact_fecha) DESC)
                               AND fact_vendedor = empl_codigo)
        SET @vendedor = (SELECT TOP 1 empl_codigo
                         FROM Empleado
                                  JOIN dbo.Factura F ON Empleado.empl_codigo = F.fact_vendedor
                         WHERE YEAR(fact_fecha) =
                               (SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY YEAR(fact_fecha) DESC)
                           AND fact_vendedor = empl_codigo
                         GROUP BY empl_codigo
                         ORDER BY SUM(fact_total) DESC)
    END

GO

DECLARE @Modiff int
EXEC ActualizarComisiones @Modiff OUTPUT
PRINT @Modiff

/*
Punto 5.
Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

IF OBJECT_ID('Fact_table','U') IS NOT NULL
DROP TABLE Fact_table
GO

CREATE TABLE Fact_table
(
    anio     CHAR(4) NOT NULL,
    mes      CHAR(2) NOT NULL,
    familia  CHAR(3) NOT NULL,
    rubro    CHAR(4) NOT NULL,
    zona     CHAR(3) NOT NULL,
    cliente  CHAR(6) NOT NULL,
    producto CHAR(8) NOT NULL,
    cantidad DECIMAL(12, 2),
    monto    DECIMAL(12, 2)
)
ALTER TABLE Fact_table ADD CONSTRAINT pk_fact_table PRIMARY KEY (anio, mes, familia, rubro, zona, cliente, producto)
GO

IF OBJECT_ID('CargarFactTable','P') IS NOT NULL
DROP PROCEDURE CargarFactTable
GO

CREATE PROC CargarFactTable
AS
BEGIN
    INSERT INTO Fact_table
    SELECT YEAR(fact_fecha),
           MONTH(fact_fecha),
           prod_familia,
           prod_rubro,
           depa_zona,
           fact_cliente,
           prod_codigo,
           SUM(item_cantidad),
           SUM(item_precio)
    FROM Factura
             JOIN dbo.Item_Factura I
                  ON Factura.fact_tipo = I.item_tipo AND Factura.fact_sucursal = I.item_sucursal AND
                     Factura.fact_numero = I.item_numero
             JOIN dbo.Producto P ON P.prod_codigo = I.item_producto
             JOIN Empleado ON Factura.fact_vendedor = Empleado.empl_codigo
             JOIN dbo.Departamento D ON D.depa_codigo = Empleado.empl_departamento
    GROUP BY YEAR(fact_fecha), MONTH(fact_fecha), prod_familia, prod_rubro, depa_zona, fact_cliente, prod_codigo
END
GO


EXEC CargarFactTable

/*
Punto 6.
Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.
*/

IF OBJECT_ID('Ej6_itemFactura','U') IS NOT NULL
DROP TABLE Ej6_itemFactura
GO

SELECT * INTO Ej6_itemFactura FROM Item_Factura
GO


IF OBJECT_ID('UnificarTablas','P') IS NOT NULL
DROP PROCEDURE UnificarTablas
GO

CREATE PROC UnificarTablas
AS
    BEGIN
        DECLARE @combo CHAR(8)
        DECLARE @combocantidad INTEGER
        DECLARE @fact_tipo CHAR(1)
        DECLARE @fact_suc CHAR(4)
        DECLARE @fact_nro CHAR(8)

        DECLARE factura_cursor CURSOR FOR
            SELECT fact_numero, fact_tipo, fact_sucursal FROM Factura
        OPEN factura_cursor
        FETCH NEXT FROM factura_cursor INTO @fact_nro, @fact_tipo, @fact_suc

        WHILE @@FETCH_STATUS = 0
        BEGIN

            DECLARE cprod CURSOR FOR
                SELECT comp_producto
                FROM Ej6_itemFactura IF1
                         JOIN Composicion C1 ON IF1.item_producto = C1.comp_componente
                WHERE IF1.item_tipo = @fact_tipo
                  AND IF1.item_sucursal = @fact_suc
                  AND IF1.item_numero = @fact_nro
                  AND IF1.item_cantidad >= C1.comp_cantidad
                GROUP BY C1.comp_producto
                HAVING COUNT(*) = (SELECT COUNT(*) FROM Composicion AS C2 WHERE C2.comp_producto = C1.comp_producto)

            OPEN cprod
            FETCH NEXT FROM cprod INTO @combo

            WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- agregar combo a Ej6_itemFactura
                    SELECT @combocantidad = MIN(FLOOR((item_cantidad / c1.comp_cantidad)))
                    FROM Ej6_itemFactura
                             JOIN Composicion C1 ON item_producto = C1.comp_componente
                    WHERE item_cantidad >= C1.comp_cantidad
                      AND item_sucursal = @fact_suc
                      AND item_numero = @fact_nro
                      AND item_tipo = @fact_tipo
                      AND C1.comp_producto = @combo

                    INSERT INTO Ej6_itemFactura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                    VALUES (@fact_tipo, @fact_suc, @fact_nro, @combo, @combocantidad,(SELECT prod_precio FROM Producto WHERE prod_codigo = @combo))

                    -- actualizo la cantidad de items para los productos q pasaron a ser combos

                    UPDATE Ej6_itemFactura
                    SET
                        item_cantidad = IF1.item_cantidad - (@combocantidad * (SELECT comp_cantidad
                                                                               FROM Composicion
                                                                               WHERE comp_producto = @combo
                                                                                 AND comp_componente = IF1.item_producto))
                    FROM Ej6_itemFactura IF1
                    WHERE IF1.item_sucursal = @fact_suc
                      AND IF1.item_numero = @fact_nro
                      AND IF1.item_tipo = @fact_tipo

                    -- eliminar los componentes sobrantes de Ej6_itemFactura

                    DELETE Ej6_itemFactura
                    WHERE item_cantidad = 0
                      AND item_sucursal = @fact_suc
                      AND item_numero = @fact_nro
                      AND item_tipo = @fact_tipo


                    FETCH NEXT FROM cprod INTO @combo

                END

                CLOSE cprod
                DEALLOCATE cprod


            FETCH NEXT FROM factura_cursor INTO @fact_nro, @fact_tipo, @fact_suc
        END
        CLOSE factura_cursor
        DEALLOCATE factura_cursor

    END

GO

EXEC UnificarTablas


/*
Punto 7.
Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.

TABLA DE VENTAS
------------------------------------------------------------------------------------------------------------
|  C�digo	|  Detalle  |  Cant. Mov.  |  Precio de Venta  |  Renglon  |           Ganancia              |
------------------------------------------------------------------------------------------------------------
|  C�digo	|  Detalle	|  Cantidad de |    Precio  	   |  Nro. de  |  Precio de venta * Cantidad     |
|  del		|  del      |  movimientos |    promedio 	   |  linea de |  -							     |
|  articulo |  articulo	|  de ventas   |    de venta	   |  la tabla |  Precio de producto * Cantidad  |
------------------------------------------------------------------------------------------------------------
*/

IF OBJECT_ID('Ventas','U') IS NOT NULL
DROP TABLE Ventas
GO

CREATE TABLE Ventas
(
    vent_renglon     INT IDENTITY(1,1),
    vent_cod         CHAR(8),
    vent_detalle     CHAR(50),
    vent_cant_mov    DECIMAL(12, 0),
    vent_precio_prom DECIMAL(12, 2),
    vent_ganancia    DECIMAL(12, 2)
)

ALTER TABLE Ventas ADD CONSTRAINT pk_ventas PRIMARY KEY (vent_renglon)
GO


IF OBJECT_ID('CargarVentas','P') IS NOT NULL
DROP PROCEDURE CargarVentas
GO

CREATE PROC CargarVentas (@FechaInicio SMALLDATETIME, @FechaFin SMALLDATETIME)
AS
    BEGIN
        INSERT INTO Ventas (vent_cod, vent_detalle, vent_cant_mov, vent_precio_prom, vent_ganancia)
            (SELECT prod_codigo,
                    prod_detalle,
                    COUNT(item_producto),
                    AVG(item_precio * item_cantidad) AS prom,
                    SUM(item_cantidad * item_precio) - SUM(item_cantidad * P.prod_precio)
             FROM Producto P
                      JOIN dbo.Item_Factura I ON P.prod_codigo = I.item_producto
                      JOIN dbo.Factura F ON F.fact_tipo = I.item_tipo
                 AND F.fact_sucursal = I.item_sucursal
                 AND F.fact_numero = I.item_numero
                 AND fact_fecha BETWEEN @FechaInicio AND @FechaFin
             GROUP BY prod_codigo, prod_detalle, prod_precio)
    END
GO

EXEC CargarVentas '2010-01-23 00:00:00', '2011-10-31 00:00:00'

/*
Punto 8.
Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:

TABLA DE DIFERENCIAS
------------------------------------------------------------------------------------
|  Codigo	|  Detalle  |    Cantidad     |  Precio generado  |  Precio facturado  |
------------------------------------------------------------------------------------
|  Codigo	|  Detalle	|  Cantidad de    |  Precio que se    |  Precio del        |
|  del		|  del      |  productos que  |  se compone a 	  |  producto		   |
|  articulo |  articulo	|  conforman el   |  traves de sus    |					   |
|           |           |  combo          |  componentes      |					   |
------------------------------------------------------------------------------------
*/

IF OBJECT_ID('Diferencias') IS NOT NULL
	DROP TABLE Diferencias
GO

CREATE TABLE Diferencias
(
    dif_codigo           CHAR(8),
    dif_detalle          CHAR(50),
    dif_cantidad         NUMERIC(6, 0),
    dif_precio_generado  DECIMAL(12, 2),
    dif_precio_facturado DECIMAL(12, 2)
)
GO

IF OBJECT_ID('CalcularPrecioGenerado') IS NOT NULL
DROP FUNCTION CalcularPrecioGenerado
GO

CREATE FUNCTION CalcularPrecioGenerado(@producto CHAR(8))
    RETURNS DECIMAL(12, 2)
AS
    BEGIN
        DECLARE @precioFinal DECIMAL(12,2)
        IF @producto IN (SELECT comp_producto FROM Composicion)
            SELECT @precioFinal = SUM(dbo.CalcularPrecioGenerado(comp_componente) * comp_cantidad)
            FROM Composicion
            WHERE comp_producto = @producto
        ELSE
            SELECT @precioFinal = prod_precio FROM Producto WHERE prod_codigo = @producto

        RETURN @precioFinal
    END
GO

IF OBJECT_ID('CargarDiferencias','P') IS NOT NULL
DROP PROCEDURE CargarDiferencias
GO

CREATE PROC CargarDiferencias
AS
    BEGIN
        INSERT INTO Diferencias
        SELECT P.prod_codigo,
               P.prod_detalle,
               COUNT(DISTINCT comp_componente),
               dbo.CalcularPrecioGenerado(prod_codigo),
               prod_precio
        FROM Producto P
                 JOIN dbo.Composicion C ON P.prod_codigo = C.comp_producto
                 JOIN dbo.Item_Factura I ON P.prod_codigo = I.item_producto
        GROUP BY prod_codigo, prod_detalle, prod_precio
    END
GO

EXEC CargarDiferencias



/*
Punto 9.
Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.
*/

IF OBJECT_ID('Ej9_itemFactura','U') IS NOT NULL
DROP TABLE Ej9_itemFactura
GO

SELECT * INTO Ej9_itemFactura FROM Item_Factura
GO

IF OBJECT_ID('Ej9_stock','U') IS NOT NULL
DROP TABLE Ej9_stock
GO

SELECT * INTO Ej9_stock FROM STOCK
GO

IF OBJECT_ID('ActualizarStockComponentes','P') IS NOT NULL
    DROP PROCEDURE ActualizarStockComponentes

CREATE PROC ActualizarStockComponentes @producto CHAR(8), @diferencia DECIMAL(12,2), @resultado int OUTPUT
AS
    BEGIN
        IF EXISTS(SELECT * FROM  Composicion WHERE comp_producto = @producto)
        BEGIN
            DECLARE @componente CHAR(8)
            DECLARE @cantidad DECIMAL(12,2)

            SET @resultado = 1

            DECLARE CR_componente CURSOR FOR
            SELECT comp_componente,
                   comp_cantidad
            FROM Composicion
            WHERE comp_producto = @producto

            OPEN CR_componente
            FETCH NEXT FROM CR_componente INTO @componente, @cantidad

            BEGIN TRANSACTION

            WHILE @@FETCH_STATUS = 0
                BEGIN
                    DECLARE @limiteDepo DECIMAL(12,2)
                    DECLARE @stockActual DECIMAL(12,2)
                    DECLARE @deposito CHAR(2)
                    DECLARE @stockNuevo DECIMAL(12,2)

                    SELECT @limiteDepo = ISNULL(stoc_stock_maximo, 0),
                           @stockActual = stoc_cantidad,
                           @deposito = stoc_deposito
                    FROM Ej9_stock
                    WHERE stoc_producto = @componente
                    ORDER BY (stoc_stock_maximo - stoc_cantidad) DESC

                    SET @stockNuevo = @stockActual + @diferencia * @cantidad

                    IF @stockNuevo <= @limiteDepo
                    BEGIN
                        UPDATE Ej9_stock
                        SET stoc_cantidad = @stockNuevo
                        WHERE stoc_deposito = @deposito
                          AND stoc_producto = @componente
                    END
                    ELSE
                    BEGIN
                        SET @resultado = 0
                    END

                    FETCH NEXT FROM CR_componente INTO @componente, @cantidad
                END

            IF @resultado = 1
                COMMIT TRANSACTION
            ELSE
                ROLLBACK TRANSACTION

            CLOSE CR_componente
            DEALLOCATE CR_componente

        END
    END
GO

IF OBJECT_ID('TriggerComponentes') IS NOT NULL
	DROP TRIGGER TriggerComponentes
GO

CREATE TRIGGER TriggerComponentes ON Ej9_itemFactura INSTEAD OF UPDATE
AS
    IF UPDATE(item_cantidad)
        AND item_producto IN (SELECT comp_producto
                              FROM Composicion)
        BEGIN
            DECLARE @diferencia DECIMAL(12,2)
            DECLARE @producto CHAR(8)
            DECLARE @numero CHAR(8)
            DECLARE @tipo CHAR(1)
            DECLARE @sucursal CHAR(4)
            DECLARE @resultado INT

            DECLARE CR_prod_compuestos CURSOR FOR
                SELECT inserted.item_producto,
                       deleted.item_cantidad - inserted.item_cantidad,
                       inserted.item_numero,
                       inserted.item_tipo,
                       inserted.item_sucursal
            FROM inserted
            JOIN deleted ON inserted.item_numero = deleted.item_numero
                                AND inserted.item_tipo = deleted.item_tipo
                                AND inserted.item_sucursal = deleted.item_sucursal
                                AND inserted.item_producto = deleted.item_producto

            OPEN CR_prod_compuestos
            FETCH NEXT FROM CR_prod_compuestos INTO @producto, @diferencia, @numero, @tipo, @sucursal

            WHILE @@FETCH_STATUS = 0
                BEGIN

                    EXEC ActualizarStockComponentes @producto, @diferencia, @resultado OUTPUT

                    IF @resultado = 1
                        BEGIN
                            UPDATE Ej9_itemFactura
                            SET item_cantidad = item_cantidad - @diferencia
                            WHERE item_numero = @numero
                              AND item_sucursal = @sucursal
                              AND item_tipo = @tipo
                              AND item_producto = @producto
                        END

                    FETCH NEXT FROM CR_prod_compuestos INTO @producto, @diferencia, @numero, @tipo, @sucursal
                END

            CLOSE CR_prod_compuestos
            DEALLOCATE CR_prod_compuestos
        END



/*
Punto 10.
Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
*/

IF OBJECT_ID('Ej10_producto','U') IS NOT NULL
DROP TABLE Ej10_producto
GO

SELECT * INTO Ej10_producto FROM Producto
GO

IF OBJECT_ID('TR_verificarStockDelete') IS NOT NULL
	DROP TRIGGER TR_verificarStockDelete
GO

CREATE TRIGGER TR_verificarStockDelete ON Ej10_producto INSTEAD OF DELETE
AS
    BEGIN
        DECLARE @producto CHAR(8)

        DECLARE prod_del CURSOR FOR
        SELECT prod_codigo FROM deleted

        OPEN prod_del
        FETCH NEXT FROM prod_del INTO @producto

        WHILE @@fetch_status = 0
            BEGIN
                DECLARE @stock DECIMAL(12,2)

                SELECT @stock = SUM(stoc_cantidad)
                FROM STOCK
                WHERE stoc_producto = @producto
                GROUP BY stoc_producto

                IF @stock > 0
                    RAISERROR ('No se pudo eliminar el producto %s porque todavia tiene stock',16,1, @producto)
                ELSE
                    DELETE Ej10_producto WHERE prod_codigo = @producto


                FETCH NEXT FROM prod_del INTO @producto
            END

        CLOSE prod_del
        DEALLOCATE prod_del

    END


/*
Punto 11.
Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
*/


IF OBJECT_ID('FX_cant_empl') IS NOT NULL
	DROP FUNCTION FX_cant_empl
GO

CREATE FUNCTION FX_cant_empl (@jefe NUMERIC(6,0))
	RETURNS INT
AS
    BEGIN
        DECLARE @empleadosACargo INT = 0
        DECLARE @empleado NUMERIC(6)

        DECLARE empleados CURSOR FOR
        SELECT empl_codigo FROM Empleado WHERE empl_jefe = @jefe

        OPEN empleados
        FETCH NEXT FROM empleados INTO @empleado

        WHILE @@FETCH_STATUS = 0
            BEGIN

                IF @empleado IN (SELECT empl_jefe FROM Empleado)
                    BEGIN
                        SET @empleadosACargo = @empleadosACargo + dbo.FX_cant_empl(@empleado) + 1
                    END
                ELSE
                     SET @empleadosACargo = @empleadosACargo + 1

                FETCH NEXT FROM empleados INTO @empleado
            END

        CLOSE empleados
        DEALLOCATE empleados

        RETURN @empleadosACargo
    END

SELECT dbo.FX_cant_empl(3)


/*
Punto 12.
Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.
*/

IF OBJECT_ID('TR_ChqeuearComp') IS NOT NULL
	DROP TRIGGER TR_ChqeuearComp
GO

CREATE TRIGGER TR_ChqeuearComp ON Composicion INSTEAD OF INSERT
AS
    BEGIN
        DECLARE @comp_prod CHAR(8)
        DECLARE @componente CHAR(8)

        DECLARE CR_composicion CURSOR FOR
        SELECT inserted.comp_producto,
               inserted.comp_componente
        FROM inserted

        OPEN CR_composicion
        FETCH NEXT FROM CR_composicion INTO @comp_prod, @componente

        WHILE @@FETCH_STATUS = 0
            BEGIN

                IF @comp_prod <> @componente
                    BEGIN
                        INSERT INTO Composicion
                        SELECT *
                        FROM inserted
                        WHERE inserted.comp_producto = @comp_prod
                          AND inserted.comp_componente = @componente
                    END
                ELSE
                    RAISERROR ('El producto no puede estar compuesto por si mismo',16,1)

                FETCH NEXT FROM CR_composicion INTO @comp_prod, @componente
            END

        CLOSE CR_composicion
        DEALLOCATE CR_composicion

    END

/*
Punto 13.
Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías
*/

IF OBJECT_ID('FX_sueldos_empl') IS NOT NULL
	DROP FUNCTION FX_sueldos_empl
GO

CREATE FUNCTION FX_sueldos_empl (@jefe NUMERIC(6,0))
	RETURNS DECIMAL(12,2)
AS
    BEGIN
        DECLARE @sueldosEmpleadosACargo DECIMAL(12,2) = 0
        DECLARE @empleado NUMERIC(6)

        DECLARE empleados CURSOR FOR
        SELECT empl_codigo FROM Empleado WHERE empl_jefe = @jefe

        OPEN empleados
        FETCH NEXT FROM empleados INTO @empleado

        WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @empleado IN (SELECT empl_jefe FROM Empleado)
                    BEGIN
                        SET @sueldosEmpleadosACargo = @sueldosEmpleadosACargo + dbo.FX_sueldos_empl(@empleado) + (SELECT empl_salario FROM Empleado WHERE empl_codigo = @empleado)
                    END
                ELSE
                     SET @sueldosEmpleadosACargo = @sueldosEmpleadosACargo + (SELECT empl_salario FROM Empleado WHERE empl_codigo = @empleado)

                FETCH NEXT FROM empleados INTO @empleado
            END

        CLOSE empleados
        DEALLOCATE empleados

        RETURN @sueldosEmpleadosACargo
    END

SELECT dbo.FX_sueldos_empl(3)

IF OBJECT_ID('TR_verificarSalarioJefes') IS NOT NULL
	DROP TRIGGER TR_verificarSalarioJefes
GO

CREATE TRIGGER TR_verificarSalarioJefes ON Empleado INSTEAD OF UPDATE
AS
    IF UPDATE(empl_salario)
        BEGIN
            DECLARE @jefe NUMERIC(6)
            DECLARE @salarioJefe DECIMAL(12,2)

            DECLARE CR_Jefes CURSOR FOR
            SELECT empl_codigo,
                   empl_salario
            FROM inserted

            OPEN CR_Jefes
            FETCH NEXT FROM CR_Jefes INTO @jefe, @salarioJefe

            WHILE @@FETCH_STATUS = 0
                BEGIN
                    IF @salarioJefe > 0.2 * dbo.FX_sueldos_empl(@jefe) AND @jefe IN (SELECT empl_jefe FROM Empleado)
                        BEGIN
                            RAISERROR('No se le puede designar ese salario al empleado: %s',16,1,@jefe)
                        END
                    ELSE
                        BEGIN
                            UPDATE Empleado
                            SET empl_salario = @salarioJefe
                            WHERE empl_codigo = @jefe
                        END
                    FETCH NEXT FROM CR_Jefes INTO @jefe, @salarioJefe
                END

            CLOSE CR_Jefes
            DEALLOCATE CR_Jefes

        END


