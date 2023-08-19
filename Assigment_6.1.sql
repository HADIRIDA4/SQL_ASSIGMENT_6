WITH FilmRentalCounts AS (
    SELECT
        film.film_id,
        COUNT(DISTINCT rental.rental_id) AS rental_count,
        AVG(COUNT(DISTINCT rental.rental_id)) OVER () AS average_rental_count
    FROM film
    INNER JOIN inventory ON inventory.film_id = film.film_id
    INNER JOIN rental ON rental.inventory_id = inventory.inventory_id
    GROUP BY film.film_id
)
SELECT
    FilmRentalCounts.film_id,
	FilmRentalCounts.rental_count,
    CASE
        WHEN rental_count > average_rental_count THEN 'Above Average'
        WHEN rental_count < average_rental_count THEN 'Below Average'
        ELSE 'Average'
    END AS rental_status
FROM FilmRentalCounts;
------ part_2
WITH cte_rental_duration AS (
    SELECT 
        rental_id,
        EXTRACT(DAY FROM (return_date - rental_date)) * 24 + EXTRACT(HOUR FROM (return_date - rental_date)) AS duration_hours
    FROM public.rental
),
cte_total_payment AS (
    SELECT 
        rental_id,
        SUM(amount) AS total_revenue
    FROM payment
    GROUP BY rental_id
),
cte_top_3_categories AS (
    SELECT
        se_rental.customer_id,
        se_category.name,
        COUNT(rental_id) AS top_fav
    FROM rental AS se_rental
    INNER JOIN inventory AS se_inventory ON se_inventory.inventory_id = se_rental.inventory_id
    INNER JOIN film AS se_film ON se_film.film_id = se_inventory.film_id
    INNER JOIN film_category AS se_film_category ON se_film_category.film_id = se_film.film_id
    INNER JOIN category AS se_category ON se_category.category_id = se_film_category.category_id
    GROUP BY se_rental.customer_id, se_category.name
),
cte_top_categories_ranked AS (
    SELECT
        se_rental.customer_id,
        se_category.name,
        COUNT(rental_id) AS top_fav,
        ROW_NUMBER() OVER (PARTITION BY se_rental.customer_id ORDER BY COUNT(rental_id) DESC) AS category_rank
    FROM rental AS se_rental
    INNER JOIN inventory AS se_inventory ON se_inventory.inventory_id = se_rental.inventory_id
    INNER JOIN film AS se_film ON se_film.film_id = se_inventory.film_id
    INNER JOIN film_category AS se_film_category ON se_film_category.film_id = se_film.film_id
    INNER JOIN category AS se_category ON se_category.category_id = se_film_category.category_id
    GROUP BY se_rental.customer_id, se_category.name
)
SELECT
    se_rental.customer_id,
    ROUND(AVG(cte_rental_duration.duration_hours), 2) AS avg_rental_hours,
    SUM(cte_total_payment.total_revenue) AS total_revenue,
    MAX(CASE WHEN cte_top_categories_ranked.category_rank = 1 THEN cte_top_categories_ranked.name END) AS first_favorite,
    MAX(CASE WHEN cte_top_categories_ranked.category_rank = 2 THEN cte_top_categories_ranked.name END) AS second_favorite,
    MAX(CASE WHEN cte_top_categories_ranked.category_rank = 3 THEN cte_top_categories_ranked.name END) AS third_favorite
FROM rental AS se_rental
INNER JOIN cte_rental_duration ON se_rental.rental_id = cte_rental_duration.rental_id
INNER JOIN cte_total_payment ON se_rental.rental_id = cte_total_payment.rental_id
INNER JOIN cte_top_categories_ranked ON cte_top_categories_ranked.customer_id = se_rental.customer_id
GROUP BY se_rental.customer_id
ORDER BY se_rental.customer_id;

