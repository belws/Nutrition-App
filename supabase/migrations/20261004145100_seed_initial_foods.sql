-- Primary generic-food source: Public Health England, CoFID 2021.
-- https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid
-- CoFID carbohydrate/sugar values retain its published monosaccharide-equivalent
-- methodology; they are not normalized to EU product-label methodology.
-- Energy retains CoFID's published calculation methodology. Fiber uses AOAC values.
-- CoFID salt (g) = sodium (mg) * 2.5 / 1000. Trace/unavailable values remain NULL.
-- Manufacturer declarations serve only as generic reference proxies:
-- Milk: https://www.olympos.gr/en/product/light/ (per 100 ml).
-- Greek yogurt: https://home.fage/yogurts/fage-total-2 (plain strained, per 100 g).
-- Cascaval: https://hochland.ro/produse/cascaval/ (Clasic, unsmoked, per 100 g).
-- Manufacturer fiber is undeclared and remains NULL.
-- Preparation: edible portions; raw skinless chicken light meat is a breast proxy;
-- raw egg excludes shell; rice/pasta are dry, uncooked; potato is raw and peeled;
-- bread is baked, not toasted; banana excludes peel; apple includes skin, not core;
-- tomatoes are raw; salmon is raw farmed flesh; white haricot beans are boiled
-- without salt (beans, not soup). Oil values are per 100 g, not per 100 ml.
-- Salmon fiber is intentionally NULL: CoFID's questionable 0.2 g value has not
-- been established as actual dietary fiber. No assumed zero is substituted.

INSERT INTO public.foods (
    name, category, preparation_state, nutrition_basis_unit,
    energy_kcal, protein_g, carbohydrates_g, sugars_g,
    fat_g, saturated_fat_g, fiber_g, salt_g
)
VALUES
    -- CoFID 18-290
    ('Piept de pui, crud, fără piele', 'Carne', 'raw', 'g',
     106, 24.0, 0, 0, 1.1, 0.30, 0, 0.15),
    -- CoFID 12-937
    ('Ou de găină, crud', 'Ouă', 'raw', 'g',
     131, 12.6, NULL, NULL, 9.0, 2.52, 0, 0.385),
    -- OLYMPOS 1.5% manufacturer proxy
    ('Lapte 1.5%', 'Lactate', NULL, 'ml',
     45, 3.2, 4.7, 4.7, 1.5, 0.8, NULL, 0.08),
    -- FAGE Total 2% manufacturer proxy
    ('Iaurt grecesc 2%, simplu, strecurat', 'Lactate', NULL, 'g',
     70, 9.9, 3.0, 3.0, 2.0, 1.3, NULL, 0.10),
    -- Hochland Clasic manufacturer proxy
    ('Cașcaval, neafumat', 'Lactate', NULL, 'g',
     328, 23.0, 0.5, 0.5, 26.0, 17.0, NULL, 1.7),
    -- CoFID 11-861
    ('Orez alb, cu bob lung, uscat', 'Cereale', 'dry', 'g',
     355, 6.7, 85.1, 0.2, 1.0, 0.25, 1.1, 0.0025),
    -- CoFID 11-716
    ('Paste, uscate', 'Cereale', 'dry', 'g',
     343, 11.3, 75.6, 2.1, 1.6, 0.23, NULL, 0.005),
    -- CoFID 13-489
    ('Cartof, crud, fără coajă', 'Legume', 'raw', 'g',
     82, 1.9, 19.6, 0.9, 0.1, 0.03, 2.0, 0.005),
    -- CoFID 11-1145
    ('Pâine albă, neprăjită', 'Panificație', 'baked', 'g',
     236, 8.7, 48.7, 3.0, 2.1, NULL, 2.9, 1.0),
    -- CoFID 14-318
    ('Banană, crudă, fără coajă', 'Fructe', 'raw', 'g',
     81, 1.2, 20.3, 18.1, 0.1, 0.04, 1.4, NULL),
    -- CoFID 14-319
    ('Măr, crud, cu coajă', 'Fructe', 'raw', 'g',
     51, 0.6, 11.6, 11.6, 0.5, 0.12, 1.2, 0.0025),
    -- CoFID 13-517
    ('Roșii, crude', 'Legume', 'raw', 'g',
     14, 0.5, 3.0, 3.0, 0.1, 0.03, 1.0, 0.005),
    -- CoFID 17-038
    ('Ulei de măsline', 'Grăsimi și uleiuri', NULL, 'g',
     899, NULL, 0, 0, 99.9, 14.30, 0, NULL),
    -- CoFID 16-356; fiber intentionally NULL
    ('Somon de crescătorie, crud', 'Pește', 'raw', 'g',
     217, 20.4, 0, 0, 15.0, 2.77, NULL, 0.1075),
    -- CoFID 13-087
    ('Fasole albă, fiartă, fără sare', 'Leguminoase', 'boiled', 'g',
     95, 6.6, 17.2, 0.8, 0.5, 0.10, NULL, 0.0375);
