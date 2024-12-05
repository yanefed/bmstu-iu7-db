SELECT *
FROM generate_series(1, 8, 1) AS A, generate_series(1, 8, 1) AS B,
generate_series(1, 8, 1) AS C, generate_series(1, 8, 1) AS D,
generate_series(1, 8, 1) AS E, generate_series(1, 8, 1) AS F,
generate_series(1, 8, 1) AS G, generate_series(1, 8, 1) AS H
WHERE (A <> B) and (A <> C) and (A <> D) and (A <> E) and (A <> F) and (A <> G) and (A <> H) and
(B <> A) and (B <> C) and (B <> D) and (B <> E) and (B <> F) and (B <> G) and (B <> H) and
(C <> A) and (C <> B) and (C <> D) and (C <> E) and (C <> F) and (C <> G) and (C <> H) and
(D <> A) and (D <> B) and (D <> C) and (D <> E) and (D <> F) and (D <> G) and (D <> H) and
(E <> A) and (E <> B) and (E <> C) and (E <> D) and (E <> F) and (E <> G) and (E <> H) and
(F <> A) and (F <> B) and (F <> C) and (F <> D) and (F <> E) and (F <> G) and (F <> H) and
(G <> A) and (G <> B) and (G <> C) and (G <> D) and (G <> E) and (G <> F) and (G <> H) and
(H <> A) and (H <> B) and (H <> C) and (H <> D) and (H <> E) and (H <> F) and (H <> G) and
(ABS(A - B) <> 1) and (ABS(A - C) <> 2) and (ABS(A - D) <> 3) and (ABS(A - E) <> 4) and (ABS(A - F) <> 5) and (ABS(A - G) <> 6) and (ABS(A - H) <> 7) and
(ABS(B - A) <> 1) and (ABS(B - C) <> 1) and (ABS(B - D) <> 2) and (ABS(B - E) <> 3) and (ABS(B - F) <> 4) and (ABS(B - G) <> 5) and (ABS(B - H) <> 6) and
(ABS(C - A) <> 2) and (ABS(C - B) <> 1) and (ABS(C - D) <> 1) and (ABS(C - E) <> 2) and (ABS(C - F) <> 3) and (ABS(C - G) <> 4) and (ABS(C - H) <> 5) and
(ABS(D - A) <> 3) and (ABS(D - B) <> 2) and (ABS(D - C) <> 1) and (ABS(D - E) <> 1) and (ABS(D - F) <> 2) and (ABS(D - G) <> 3) and (ABS(D - H) <> 4) and
(ABS(E - A) <> 4) and (ABS(E - B) <> 3) and (ABS(E - C) <> 2) and (ABS(E - D) <> 1) and (ABS(E - F) <> 1) and (ABS(E - G) <> 2) and (ABS(E - H) <> 3) and
(ABS(F - A) <> 5) and (ABS(F - B) <> 4) and (ABS(F - C) <> 3) and (ABS(F - D) <> 2) and (ABS(F - E) <> 1) and (ABS(F - G) <> 1) and (ABS(F - H) <> 2) and
(ABS(G - A) <> 6) and (ABS(G - B) <> 5) and (ABS(G - C) <> 4) and (ABS(G - D) <> 3) and (ABS(G - E) <> 2) and (ABS(G - F) <> 1) and (ABS(G - H) <> 1) and
(ABS(H - A) <> 7) and (ABS(H - B) <> 6) and (ABS(H - C) <> 5) and (ABS(H - D) <> 4) and (ABS(H - E) <> 3) and (ABS(H - F) <> 2) and (ABS(H - G) <> 1);
