// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library BN254 {
    uint256 internal constant SCALAR_FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant BASE_FIELD_SIZE =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct Scalar {
        uint256 data;
    }

    struct G1Affine {
        uint256 x;
        uint256 y;
    }

    function g1Basepoint() internal pure returns (G1Affine memory basepoint_) {
        return G1Affine(1, 2);
    }

    function scalarFromUint256(uint256 a_) internal pure returns (Scalar memory scalar_) {
        scalar_ = Scalar(a_);

        require(validateScalar(scalar_), "BN: invalid scalar");
    }

    function scalarFromUint256ModScalar(uint256 a_) internal pure returns (Scalar memory scalar_) {
        return Scalar(a_ % SCALAR_FIELD_SIZE);
    }

    function g1PointFromAffine(
        uint256 x_,
        uint256 y_
    ) internal pure returns (G1Affine memory point_) {
        point_ = G1Affine(x_, y_);

        require(validateG1Point(point_), "BN254: invalid point");
    }

    function pointNeg(G1Affine memory a_) internal pure returns (G1Affine memory r_) {
        return G1Affine(a_.x, BASE_FIELD_SIZE - a_.y);
    }

    function pointEqual(
        G1Affine memory a_,
        G1Affine memory b_
    ) internal pure returns (bool isEqual_) {
        return a_.x == b_.x && a_.y == b_.y;
    }

    function pointSub(
        G1Affine memory a_,
        G1Affine memory b_
    ) internal view returns (G1Affine memory r_) {
        return pointAdd(a_, pointNeg(b_));
    }

    function pointAdd(
        G1Affine memory a_,
        G1Affine memory b_
    ) internal view returns (G1Affine memory r_) {
        assembly {
            let call_ := mload(0x40)
            mstore(0x40, add(call_, 0x80))

            mstore(call_, mload(a_))
            mstore(add(call_, 0x20), mload(add(a_, 0x20)))
            mstore(add(call_, 0x40), mload(b_))
            mstore(add(call_, 0x60), mload(add(b_, 0x20)))

            pop(staticcall(gas(), 0x6, call_, 0x80, r_, 0x40))
        }
    }

    function pointMul(
        G1Affine memory p_,
        Scalar memory a_
    ) internal view returns (G1Affine memory r_) {
        assembly {
            let call_ := mload(0x40)
            mstore(0x40, add(call_, 0x60))

            mstore(call_, mload(p_))
            mstore(add(call_, 0x20), mload(add(p_, 0x20)))
            mstore(add(call_, 0x40), mload(a_))

            pop(staticcall(gas(), 0x7, call_, 0x60, r_, 0x40))
        }
    }

    function basepointMul(Scalar memory a_) internal view returns (G1Affine memory point_) {
        return pointMul(g1Basepoint(), a_);
    }

    function scalarAdd(
        Scalar memory a_,
        Scalar memory b_
    ) internal pure returns (Scalar memory r_) {
        return Scalar(addmod(a_.data, b_.data, SCALAR_FIELD_SIZE));
    }

    function scalarSub(
        Scalar memory a_,
        Scalar memory b_
    ) internal pure returns (Scalar memory r_) {
        if (a_.data > b_.data) {
            return Scalar(a_.data - b_.data);
        }

        return Scalar(SCALAR_FIELD_SIZE - (b_.data - a_.data));
    }

    function scalarMul(
        Scalar memory a_,
        Scalar memory b_
    ) internal pure returns (Scalar memory r_) {
        return Scalar(mulmod(a_.data, b_.data, SCALAR_FIELD_SIZE));
    }

    function validateScalar(BN254.Scalar memory scalar_) internal pure returns (bool isValid_) {
        return scalar_.data < SCALAR_FIELD_SIZE;
    }

    function validateG1Point(BN254.G1Affine memory point_) internal pure returns (bool isValid_) {
        if (point_.x == 0 && point_.y == 0) {
            return true;
        }

        if (point_.x > BASE_FIELD_SIZE || point_.y > BASE_FIELD_SIZE) {
            return false;
        }

        uint256 lhs_ = mulmod(point_.y, point_.y, BASE_FIELD_SIZE);
        uint256 rhs_ = mulmod(point_.x, point_.x, BASE_FIELD_SIZE);
        rhs_ = mulmod(rhs_, point_.x, BASE_FIELD_SIZE);
        rhs_ = (rhs_ + 3) % BASE_FIELD_SIZE;

        return lhs_ == rhs_;
    }
}
