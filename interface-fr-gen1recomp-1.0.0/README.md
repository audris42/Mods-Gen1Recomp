# Interface française pour Gen1Recomp

Ce mod compagnon complète le pack translation-fr avec les textes du lanceur
ajoutés ou laissés vides dans Gen1Recomp 0.2.4. Il vise le français
métropolitain et ne contient ni ROM, ni sauvegarde, ni donnée extraite d'une
cartouche.

Le catalogue contient 269 traductions non vides : 241 lacunes du lanceur,
deux textes de mise à jour, seize valeurs dynamiques et dix corrections
ciblées du pack principal.

## Installation

1. Gardez le pack translation-fr installé et activé.
2. Compressez le contenu de ce dossier en ZIP, avec manifest.json à la racine.
3. Dans le lanceur, ouvrez MODS, puis choisissez Import mod .zip.
4. Activez Interface française et redémarrez l'application si le lanceur le
   demande.

L'identifiant zz-interface-fr et la priorité 200 chargent ce complément après
le pack principal. Le catalogue ne reprend aucune de ses valeurs non vides,
hors dix corrections volontaires : Name, Reset, Save, FAITHFUL RATIO et six
libellés d’options nécessaires à une interface cohérente.

## Compatibilité et limites

- Cible testée : Gen1Recomp 0.2.4 (versions antérieures à 1.0.0).
- Jeux déclarés : tous les jeux pris en charge par cette version.
- Les noms et descriptions provenant de mods, d'index distants ou de schémas
  d'options tiers restent dans la langue choisie par leurs auteurs.
- Les quelques valeurs d'options dessinées directement sans passer par le
  registre Strings ne peuvent pas être traduites par ce mod minimal.

Pour modifier une formulation, éditez uniquement lang/strings.lua en
conservant exactement les marqueurs de format tels que %s, %d et %%.
