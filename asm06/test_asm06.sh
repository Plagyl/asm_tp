#!/bin/bash

# Compilation du programme
nasm -f elf64 asm06.s -o asm06.o && ld asm06.o -o asm06

# Vérifier si la compilation a réussi
if [ ! -f asm06 ]; then
    echo "❌ Erreur : La compilation a échoué !"
    exit 1
fi

echo "✅ Compilation réussie !"
echo "======================="
echo "Début des tests..."
echo "======================="

# Fonction pour exécuter un test et comparer la sortie
run_test() {
    expected_output="$1"
    shift
    output=$(./asm06 "$@" 2>/dev/null)

    if [ "$output" == "$expected_output" ]; then
        echo "✅ Test réussi : ./asm06 $@ -> $output"
    else
        echo "❌ Test échoué : ./asm06 $@"
        echo "   Attendu : $expected_output"
        echo "   Obtenu  : $output"
    fi
}

# Lancer les tests
run_test "12" 5 7
run_test "42" 0 42
run_test "-15" -5 -10
run_test "30" 50 -20
run_test "1000000" 999999 1

# Tests avec erreurs attendues
run_test "Usage: ./asm06 <num1> <num2>" 42
run_test "Usage: ./asm06 <num1> <num2>"
run_test "Usage: ./asm06 <num1> <num2>" 5 6 7
run_test "Usage: ./asm06 <num1> <num2>" 5 a

echo "======================="
echo "Tous les tests sont terminés !"
echo "======================="

