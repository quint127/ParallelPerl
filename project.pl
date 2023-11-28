
use strict;
use warnings;
use Parallel::ForkManager;

# Підпрограма для обчислення суми елементів масиву
sub sum_array {
    my ($array) = @_;
    my $sum = 0;

    for my $element (@$array) {
        $sum += $element;
    }

    return $sum;
}

# Підпрограма для паралельного обчислення суми по декількох масивах
sub parallel_sum {
    my ($arrays, $max_processes) = @_;

    # Створення об'єкта для керування паралельними процесами
    my $pm = Parallel::ForkManager->new($max_processes);
    my @partial_sums;   

    # Ітерація по масивам для обчислення часткових сум паралельно
    for my $array (@$arrays) {
        $pm->start and next; // Запуск нового процесу, перехід до наступної ітерації в батьківському процесі

        # Обчислення часткової суми для поточного масиву
        my $partial_sum = sum_array($array);

        # Завершення дочірнього процесу, передача даних часткової суми
        $pm->finish(0, { partial_sum => $partial_sum });
    }

    # Очікування завершення всіх дочірніх процесів
    $pm->wait_all_children;

    # Обробка завершення кожного дочірнього процесу
    $pm->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;

            # Збір часткових сум з кожного дочірнього процесу
            push @partial_sums, $data->{partial_sum};
        }
    );

    # Обчислення загальної суми з часткових сум
    return sum_array(\@partial_sums);
}

# Створення масиву з 10 масивами, кожен з 5 випадковими елементами
my @arrays;
for my $i (1..10) {
    push @arrays, [map { int(rand(10)) } 1..5];
}

# Вивід початкових масивів
for my $i (0..$#arrays) {
    print "Масив $i: [@{$arrays[$i]}]\n";
}

# Обчислення загальної суми паралельно за допомогою 4 процесів
my $total_sum = parallel_sum(\@arrays, 4);

# Вивід загальної суми
print "Загальна сума: $total_sum\n";
