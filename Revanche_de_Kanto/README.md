# Revanche de Kanto

Mod de seconde campagne pour **Gen1Recomp**, compatible avec Pokémon Rouge,
Bleu et Jaune.

## Fonctionnement

- Le mod attend que la Ligue soit battue (`EVENT_BEAT_CHAMPION_RIVAL`).
- Le cycle commence au retour à **Bourg Palette** ou dans la chambre de
  départ.
- Les dresseurs ordinaires déjà vaincus sur les routes, dans les grottes,
  bâtiments et arènes peuvent alors être combattus une nouvelle fois.
- Une défaite ne valide rien : le dresseur reste disponible.
- Une victoire valide uniquement cette revanche.
- Une nouvelle entrée au Hall of Fame permet de démarrer un nouveau cycle au
  prochain retour à Bourg Palette.

La Ligue possède déjà son propre système de revanche dans Gen1Recomp. Les
Rivaux, boss, cadeaux-combats et autres rencontres pilotées par un scénario
gardent donc leur comportement d'origine. Ce choix empêche la réouverture de
portes, la répétition de cinématiques ou l'obtention en double d'objets et de
badges.

## Sécurité des données

Le mod :

- ne lit, ne modifie et ne produit **aucune ROM** ;
- n'efface aucun drapeau `EVENT_BEAT_*` ;
- n'efface aucune entrée `defeatedTrainers` ;
- enregistre seulement ses propres victoires dans l'espace `mod.save` réservé
  à `revanche_kanto`.

Désactiver le mod rétablit immédiatement le comportement normal de la partie.

## Installation

1. Dans Gen1Recomp, ouvrez le gestionnaire de mods avec **F10**.
2. Choisissez **Import Mod** et sélectionnez `Revanche_de_Kanto-1.0.0.zip`.
3. Activez **Revanche de Kanto**.
4. Acceptez la permission `engine_internals` : elle sert uniquement à
   interroger le statut des dresseurs dans le moteur Lua.
5. Relancez le jeu si Gen1Recomp le demande.

Le mod fonctionne aussi avec une sauvegarde post-Ligue existante : entrez à
Bourg Palette ou dans la chambre de départ pour lancer le premier cycle.

## Compatibilité vérifiée

- Gen1Recomp 0.1.96, 0.1.98 et 0.1.99 (API mods 2)
- Pokémon Rouge (USA/Europe)
- Pokémon Bleu (USA/Europe)
- Pokémon Jaune (USA/Europe)
- Sauvegardes Gen1Recomp et sauvegardes `.sav` importées

## Vérification rapide

1. Chargez une partie ayant terminé la Ligue.
2. Revenez à Bourg Palette : un message annonce le nombre de dresseurs du
   cycle.
3. Retrouvez un dresseur ordinaire déjà vaincu et affrontez-le.
4. Après une défaite, vérifiez qu'il reste combattable.
5. Après une victoire, vérifiez qu'il redonne son dialogue d'après-combat et
   ne relance plus le combat pendant ce cycle.
