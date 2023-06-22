### Intro 
to allow for easy L2 adoption in smart accounts, a progpagation system of the registry and its attestations would be very beneficial.
attestations could be propagated to L2s using bridges/oracles. 

### Challenges 

bytecode equivalence across L2s can not be guaranteed. propagation of attestations to T3/T3 L2s is probably not possible https://vitalik.ca/general/2022/08/04/zkevm.html

bridges must be trusted. who defines the bridges that are used to propagate the attestations


### Hashi
Gnosis' Hashi is an EVM Hash Oracle Aggregator, designed to facilitate a principled approach to cross-chain bridge security.
RSRegistry could allow for propagation of attestations utilizing hashi. 
during propagation, the bytecode checksum shall be compared to avoid incorrect propagations


