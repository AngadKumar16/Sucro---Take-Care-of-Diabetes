#!/usr/bin/env python3
"""Builds DiabetesCare/Resources/Foods.json from USDA FoodData Central.

Source: FNDDS ("Survey foods"), the foods as people actually eat them, with
household portions ("1 slice", "1 cup"). Public domain (CC0).

    curl -O https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_csv_2024-10-31.zip
    unzip FoodData_Central_survey_food_csv_2024-10-31.zip
    python3 scripts/make-food-db.py FoodData_Central_survey_food_csv_2024-10-31 DiabetesCare/Resources/Foods.json

The CSVs stay out of git; only the JSON is committed.
"""
import csv
import json
import os
import sys

CARBS = "205"    # Carbohydrate, by difference (g per 100 g); FNDDS files use nutrient numbers
FIBER = "291"    # Fiber, total dietary (g per 100 g)
SKIP = ("Milk, human", "Infant formula", "Baby food")


def read(folder, name):
    with open(os.path.join(folder, name), newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def main(folder, out):
    foods = {row["fdc_id"]: row["description"] for row in read(folder, "food.csv")}
    nutrients = {}
    for row in read(folder, "food_nutrient.csv"):
        if row["nutrient_id"] in (CARBS, FIBER):
            nutrients.setdefault(row["fdc_id"], {})[row["nutrient_id"]] = float(row["amount"] or 0)
    portions = {}
    for row in read(folder, "food_portion.csv"):
        grams = float(row["gram_weight"] or 0)
        desc = row["portion_description"].strip()
        if grams <= 0 or not desc or desc == "Quantity not specified":
            continue
        portions.setdefault(row["fdc_id"], []).append((int(row["seq_num"] or 0), desc, round(grams, 1)))

    rows = []
    for fdc_id, name in foods.items():
        if name.startswith(SKIP):
            continue
        values = nutrients.get(fdc_id, {})
        if CARBS not in values:
            continue
        ps = [[d, g] for _, d, g in sorted(portions.get(fdc_id, []))][:6]
        rows.append({
            "i": int(fdc_id),
            "n": name,
            "c": round(values[CARBS], 1),
            "f": round(values.get(FIBER, 0), 1),
            "p": ps,
        })
    rows.sort(key=lambda r: r["n"].lower())
    data = {
        "source": "USDA FoodData Central, FNDDS (public domain)",
        "foods": rows,
    }
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"), ensure_ascii=False)
    print(f"{len(rows)} foods → {out} ({os.path.getsize(out) // 1024} KB)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
